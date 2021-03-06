function splitToStyleTransfer(realImages,estimatedMasks,targetDir, optionFile)
%copies to the style transfer input folder
%both real images and estimated masks has the same format, below their root
%there are the clusters

optionT = readtable(optionFile);

%doc: the folder structure of style transfer is:
%split0 -> p2ptrain -> cluster1 (duplicated images)
%                   -> cluster2
%       -> inputClusters -> cluster1 (simple images)
%                        -> cluster2
%split1 -> etc.

d = dir(realImages);
dirFlags = [d.isdir];
dirFlags([1,2]) = false;
clusterNames = {d(dirFlags).name};

% intervals = splitToIntervals(length(clusterNames)-1,optionT.Weight); % -1 to ignore thrash
intervals = splitToIntervals(length(clusterNames)-2,optionT.Weight); % -2 to ignore thrash and missing... too

for i=1:length(optionT.SplitName)
    if iscell(optionT.SplitName)
        currentSplitDir = fullfile(targetDir,optionT.SplitName{i});
    else
        currentSplitDir = fullfile(targetDir,num2str(optionT.SplitName(i),'%d'));
    end
    currentInputClusters = fullfile(currentSplitDir,'input-clusters');
    currentPredsClusters = fullfile(currentSplitDir,'preds-clusters');
	disp(currentSplitDir);
    mkdir(currentSplitDir);    
    for j=intervals(i):intervals(i+1)-1
        currentClusterDir = fullfile(currentInputClusters,clusterNames{j});
        currentPredDir =fullfile(currentPredsClusters,clusterNames{j});
        if strcmp(clusterNames{j},'group_095')
            disp('stop')
        end
        %copy patched images from the original folders, also creates the
        %folder
%         splitimagesCustom(fullfile(realImages,clusterNames{j}), currentClusterDir , 256, 256,1);
%         splitimagesCustom(fullfile(estimatedMasks,clusterNames{j}), currentPredDir , 256, 256,0);
        splitimagesCustomNOpad(fullfile(realImages,clusterNames{j}), currentClusterDir , 256, 256,1);
        splitimagesCustomNOpad(fullfile(estimatedMasks,clusterNames{j}), currentPredDir , 256, 256,0);
        
    end    
    genpix2pixtrain(currentPredsClusters,currentInputClusters,fullfile(currentSplitDir,'p2ptrain'));
    
end




end


% splits the images in the given inpDir into w*h sized patches
% the result will be in the outDir/{image_fname_wo_ext}_x_y.{ext}
function splitimagesCustom(inpDir, outDir, w, h, realImage)
%customized split image, it collects everything to outDir and not to
%outDir/imageName/imageName_wo_ext
%collects everything in the folder
%real image is a bool that indicates if we need to convert our img to rgb

    %w = 256;
    %h = 256;
    %ext = '.png';
    %root_dir = '/home/biomag/etasnadi/input/processed-dataset'

    conts = dir([inpDir, '/*']);
    out_fname_pref = outDir;
    mkdir(out_fname_pref);
    for fid=3:numel(conts)
        fname = conts(fid).name;

        [~, fnamewext, ext] = fileparts(fname);        
        if realImage
            im = im2double(imReadGeneral(fullfile(inpDir, fname)));
        else
            im = imread(fullfile(inpDir, fname));
        end
        size_im = size(im);
        xs = size_im(2);
        ys = size_im(1);
        
        xpatches = uint32(floor(xs/w));
        ypatches = uint32(floor(ys/h));
        disp(['img: ' fnamewext  ' xpatches: ' num2str(xpatches) ' ypatches: ' num2str(ypatches)]);        
        xshift = (xs-(xpatches*w))/2;
        yshift = (ys-(ypatches*h))/2;
        %if the img is not big enough
        if (xpatches*ypatches == 0)
            if realImage
                imgR = im(:,:,1);
                imgG = im(:,:,2);
                imgB = im(:,:,3);            
                medR = median(imgR(:));
                medG = median(imgG(:));
                medB = median(imgB(:));
                paddedImg = ones(h,w,3);
                paddedImg(:,:,1) = medR;
                paddedImg(:,:,2) = medG;
                paddedImg(:,:,3) = medB;
            else
                paddedImg = uint16(zeros(h,w));
            end
            if w>xs && h>ys
                xstart = floor((w-xs)/2);
                ystart = floor((h-ys)/2);
                paddedImg(ystart:ystart+ys-1,xstart:xstart+xs-1,:) = im;
            elseif w>xs
                xstart = floor((w-xs)/2);
                ystart = floor((ys-h)/2);
                paddedImg(:,xstart:xstart+xs-1,:) = im(ystart:ystart+h-1,:,:);
            else
                xstart = floor((xs-w)/2);
                ystart = floor((h-ys)/2);
                paddedImg(ystart:ystart+ys-1,:,:) = im(:,xstart:xstart+w-1,:);
            end
            out_fname = fullfile(out_fname_pref, fname);
            imwrite(paddedImg, out_fname);
        else
            for xpatch=1:xpatches
                for ypatch = 1:ypatches
                    xfrom = xshift + ((xpatch-1)*w+1);
                    xto = xshift + (xpatch*w);
                    yfrom = yshift + ((ypatch-1)*h+1);
                    yto = yshift + (ypatch*h);
                    disp(strcat(num2str(xfrom), '-', num2str(xto)));
                    out_fname = fullfile(out_fname_pref, [fnamewext, '_', num2str(xpatch), '_', num2str(ypatch), ext]);
                    disp(['imwrite ' out_fname]);
                    imwrite(im(yfrom:yto, xfrom:xto,:), out_fname);
                    %disp(strcat(num2str(xpatch), fullfile(out_dir, 'asd'), num2str(ypatch)));
                end
            end
        end
    end
end

% splits images without pads to avoid squared pattern in styles
function splitimagesCustomNOpad(inpDir, outDir, w, h, realImage)
%customized split image, it collects everything to outDir and not to
%outDir/imageName/imageName_wo_ext
%collects everything in the folder
%real image is a bool that indicates if we need to convert our img to rgb

    %w = 256;
    %h = 256;
    %ext = '.png';
    %root_dir = '/home/biomag/etasnadi/input/processed-dataset'

    conts = dir([inpDir, '/*']);
    out_fname_pref = outDir;
    mkdir(out_fname_pref);
    for fid=3:numel(conts)
        fname = conts(fid).name;

        [~, fnamewext, ext] = fileparts(fname);        
        if realImage
            im = im2double(imReadGeneral(fullfile(inpDir, fname)));
        else
            im = imread(fullfile(inpDir, fname));
        end
        size_im = size(im);
        xs = size_im(2);
        ys = size_im(1);
        
        xpatches = uint32(floor(xs/w));
        ypatches = uint32(floor(ys/h));
        disp(['img: ' fnamewext  ' xpatches: ' num2str(xpatches) ' ypatches: ' num2str(ypatches)]);        
        xshift = (xs-(xpatches*w))/2;
        yshift = (ys-(ypatches*h))/2;
        %if the img is not big enough
        if (xpatches*ypatches == 0)
            % do NOT pad the images
            if realImage
                paddedImg=imresize(im,[w,h],'bicubic');
            else
                paddedImg=imresize(im,[w,h],'nearest');
            end
            out_fname = fullfile(out_fname_pref, fname);
            imwrite(paddedImg, out_fname);
        else
            for xpatch=1:xpatches
                for ypatch = 1:ypatches
                    xfrom = xshift + ((xpatch-1)*w+1);
                    xto = xshift + (xpatch*w);
                    yfrom = yshift + ((ypatch-1)*h+1);
                    yto = yshift + (ypatch*h);
                    disp(strcat(num2str(xfrom), '-', num2str(xto)));
                    out_fname = fullfile(out_fname_pref, [fnamewext, '_', num2str(xpatch), '_', num2str(ypatch), ext]);
                    disp(['imwrite ' out_fname]);
                    imwrite(im(yfrom:yto, xfrom:xto,:), out_fname);
                    %disp(strcat(num2str(xpatch), fullfile(out_dir, 'asd'), num2str(ypatch)));
                end
            end
        end
    end
end
