function [I,Iaux] = readMouseImage(varargin)
% READMOUSEIMAGE Reads a LocoMouse setup image from a MATLAB vid sturcture
% containing a LocoMouse video file.
%
% INPUT:
% vid: The Matlab video structure.
% frame_number: The scalar representing the frame number.
% Bkg: The background image.
% flip: A boolean that is true if the image must be flipped vertically.
% scale: A scale in case the image needs to be rescaled.
% ind_warp_mapping: A vid.Height*vid.Width vector with the pixel to pixel
% mapping to warp the raw images into the "undistorted" format (i.e.
% vertical lines should match between views).
% expected_im_size: The expected size for the images in vid. If the images
% are smaller they will be padded with zeros. If they are larger, an error
% will occur.
%
% OUTPUT:
% I: A grayscale image read from vid. If vid is a colour video, the image
% will be converted to grayscale as colour is not supported.

[vid,frame_number,Bkg,flip,scale,ind_warp_mapping,expected_im_size] = varargin{1:7};
h_flip      = false;
split_line  = -1;
try
    h_flip = varargin{8};
    split_line = varargin{9};
catch
end

if ischar(vid)
    vid = VideoReader(vid);
end

if ischar(Bkg) && ~isempty(Bkg)
    Bkg = imread(Bkg);
end

if ~exist('expected_im_size','var')
    expected_im_size = size(ind_warp_mapping);
end
I = read(vid,frame_number);

% Checking for colour: sometimes the LocoMouse system wrongly outputs
% colour video even though the camera is grayscale. This is potentially
% using too much disk space since the videos are in raw format...
if size(I,3) > 2
    I = rgb2gray(I);
end

% Removing bakground and spreading brightness values:
if ~isempty(Bkg)
    I = I-Bkg; 
end
m = max(I(:));
if m < 255
    I = uint8((double(I)/double(m))*255);
end

% If requested, unwarp the image:
if ~exist('ind_warp_mapping','var')
    Iaux = [];
else
    if ~isempty(ind_warp_mapping)
        I_size = size(I);
        if all(I_size <= expected_im_size)
            if ~all(I_size == expected_im_size)
                % If the map is larger than the image, the image is padded with
                % zeros.
                padd_amount = floor((expected_im_size-I_size)/2);
                I = padarray(I, padd_amount, 0,'both');
                I = padarray(I, expected_im_size-I_size-2*padd_amount,0,'post');
            end
        else
            % If the map is smaller than the image, the image is cropped to
            % the size of the map.
            error('Image is larger than expected!');
        end
        Iaux = uint8(zeros(size(ind_warp_mapping)));Iaux(:) = I(ind_warp_mapping(:));
    else
        Iaux = [];
    end
end

% Resizing it:
if scale ~= 1
    I = imresize(I,scale);
    if ~isempty(Iaux)
        Iaux = imresize(Iaux,scale);
    end
end

% vertical flip
if flip
    I = I(:,end:-1:1);
    if ~isempty(Iaux)
        Iaux = Iaux(:,end:-1:1);
    end
end

% horizontal flip of the bottom image
% if h_flip && split_line > -1
%     [I_side, I_bottom] = splitImage(I, split_line);
%     I = [I_side; I_bottom(end:-1:1,:)];
%      if ~isempty(Iaux)
%         [I_side, I_bottom] = splitImage(Iaux, split_line);
%         Iaux = [I_side; I_bottom(end:-1:1,:)];
%      end
% end