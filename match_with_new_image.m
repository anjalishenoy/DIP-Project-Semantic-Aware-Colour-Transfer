addpath(genpath('custom_toolboxes'));
addpath('functions')
tic;
A=imread('input.png');
target = imresize(A, [500 250]);

I = dir('dataset/image/*.png');
M = dir('dataset/mask/*.png');
P = dir('dataset/parsing/*.png');

for k = 1:size(I,1)
    images(k).image = imread(['dataset/image/',I(k).name]);
    images(k).mask = imread(['dataset/mask/',M(k).name]);
    images(k).F = zeros(1,11);
    images(k).parsing = imread(['dataset/parsing/',P(k).name]);
    for i=1:14
        % use covariance matrix per cluster
        icv = inv(cov(data(idx==ci,:)));    
        dif = data - repmat(c(ci,:), [size(data,1) 1]);
        % data cost is minus log likelihood of the pixel to belong to each
        % cluster according to its RGB value
        Dc(:,:,ci) = reshape(sum((dif*icv).*dif./2,2),sz(1:2));
    end
        images(k).F(i) = numel(find(images(k).parsing==i-1));
        images(k).F(i) = images(k).F(i)./numel(images(k).parsing);
    end
end

% Label the input target image 
[maskIm,responses] = scene_parse(target);

idx=knnsearch(bldgData,Feature,'k',1,'Distance','euclidean'); %Find the most similar image from the database 
cIdx=bldg_assignments(idx); % Find the bldg cluster this new image belongs to

%cIdx =  cluster(gmmDist, Feature);
%disp(cIdx)
cluster_of_new_im = find(bldg_assignments==cIdx); %% Returns all images of that building cluster

sky_assignments_of_bldg_cluster = sky_assignments(cluster_of_new_im);
%% unique skies in this cluster %%
[ uniq_skies, ia, ic] = unique(sky_assignments_of_bldg_cluster);

%%%%%%%%%% choose up to 5 skies to display %%%%%%%%%%%
chosen_sky = 1;
no_of_chosen_skies = 5;
visited = zeros([1,numData]);
jk = 1; end_flag = 0;
options = [];
while chosen_sky<6 && end_flag~=1
    for ind = 1:size(uniq_skies,1)
        a=find(ic==ind);    %gives indices corr to cluster_of_new_im
        z = find(visited==0);
        common = intersect(cluster_of_new_im(a),z);    %any image that has not been compared with target and falls in the same building cluster as target's NN'
        if numel(common) ~= 0
            visited(common(jk)) = 1;
            if pdist2(images(common(jk)).bldgFeature,Feature)<threshold && (images(common(jk)).skySize - noOfSkypixels) < sky_size_thresh
                options(chosen_sky)=common(jk);
                chosen_sky = chosen_sky + 1;
            end
        end
        vis_nodes = find(visited==1);
        if size(vis_nodes,2)>=size(cluster_of_new_im,1)
            no_of_chosen_skies = chosen_sky-1;
            end_flag = 1;
        end
    end
end

[source,index]=select_image(no_of_chosen_skies,options,images);

%%%%%%%%% replace sky using the chosen image %%%%%%%%%%%
source = imresize(source, [500 500]);
target = imresize(target, [500 500]);
source_sky_mask = (images(options(index)).maskIm==0);
%[~,s_sky_mask] = scene_parse(images(index).image);
%source_sky_mask = (s_sky_mask == 0);
target_sky_mask = (maskIm == 0);
[S,~,~,max_source_region,sr1,sr2,sc1,sc2] = FindLargestRectangles(source_sky_mask,source);
[T,~,~,max_target_region,tr1,tr2,tc1,tc2] = FindLargestRectangles(target_sky_mask,target);
source_sky = imresize(S,[size(T,1) size(T,2)]);
final = target;
final(tr1:tr2,tc1:tc2,:) = source_sky;

%source_sky=im2double(source_sky);

%figure('Name','Image for source sky selection','NumberTitle','off')
%imshow(source); %Display the superpixels of the image
%hold on;
%h2 = imfreehand;
%source_sky = im2double(h2.createMask);
%source = im2double(source);
%target = im2double(target);

%levels = 7;
%lpyramids_source = laplPyramid(target,levels); 
%lpyramids_target = laplPyramid(source,levels);
%blur_border = imgaussfilt(mat2gray(~source_sky),1.2);

%for k = 1:levels
%    blur_border = imresize(blur_border,[size(lpyramids_source(k).im,1) size(lpyramids_source(k).im,2)]);
%    blended(k).im(:,:,1) = (( (lpyramids_source(k).im(:,:,1)) .* blur_border) + ( (lpyramids_target(k).im(:,:,1)) .* (1-blur_border)))/255;
%    blended(k).im(:,:,2) = (( (lpyramids_source(k).im(:,:,2)) .* blur_border) + ( (lpyramids_target(k).im(:,:,2)) .* (1-blur_border)))/255;
%    blended(k).im(:,:,3) = (( (lpyramids_source(k).im(:,:,3)) .* blur_border) + ( (lpyramids_target(k).im(:,:,3)) .* (1-blur_border)))/255;
%end

%final = reconstruct(blended);
figure;imshowpair(target,final,'montage');str = sprintf('Original & Final Image');title(str);

toc;



