function xy = computebdymass(I)

%% bodymass computation based on object detection
% ~ 0.03s per image
%150903 - goncalo figueira (goncalo.figueira@neuro.fchampalimaud.org)

%% crop image
line = 200;
I = I(line:end,:); % bottom view
I = [I; zeros(80,size(I,2))]; % add zeros to the bottom of the image

%% pre-processing before labelling
I = I.^2;
% m = max(I(:));
% I = uint8((double(I)/double(m))*255);

%% convert to bw image
I = im2bw(I,0.2);
I = imfill(I,'holes');
I = bwareaopen(I, 10);

%% labelling and centroid computation
[L,~] = bwlabel(I,8);
stat = regionprops(L,'Centroid','Area','PixelIdxList');
[~,index] = max([stat.Area]);
image = zeros(size(I));
image(stat(index).PixelIdxList)=1;
s = regionprops(image, 'centroid');
centroids = cat(1, s.Centroid);

%% save coordinates
if ~isempty(centroids)
    xy = [centroids(:,1) centroids(:,2)+line];
end

end