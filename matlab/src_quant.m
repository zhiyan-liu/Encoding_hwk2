function [procImage] = src_quant(srcImage, src_quant_conf)
    procImage = zeros(size(srcImage));
    if strcmp(src_quant_conf.type, 'uniform')
        quant_step = src_quant_conf.step;
        if (quant_step > 255 || quant_step < 1)
            disp("Invalid step[1-255]!");
            return;
        end
        %bit count
        boundary = round(255/quant_step)+1;
        stepPixel = round(srcImage./quant_step); 
        procImage = stepPixel.*quant_step + round(quant_step/2);
        procImage(procImage>255)=255;
        procImage(procImage<0)=0;
        
        %show quantizationed image
        % imshow(procImage);
    elseif strcmp(src_quant_conf.type, 'h.261')
        quant_factor = src_quant_conf.factor;
        if quant_factor > 100 || quant_factor < 1
            disp("No factor input[1-100]!");
            return;
        end
        img_width = size(procImage, 2);
        img_height = size(procImage, 1);
        if img_height < 8
            img_height = 8;
        end
        if img_width < 8
            img_width = 8;
        end
        JPEGQuantTableOri = [ %JPEG quantization table for luma
            16,11,10,16,24,40,51,61,12,12,14,19,26,58,60,55, ...
            14,13,16,24,40,57,69,56,14,17,22,29,51,87,80,62, ...
            18,22,37,56,68,109,103,77,24,35,55,64,81,104,113,92,...
            49,64,78,87,103,121,120,101,72,92,95,98,112,100,103,99
            ]';
        %JPEG quantization table with factor(1-100)(the bigger, the worse quality)
        JPEGQuantTable =double( round(JPEGQuantTableOri.*quant_factor./10));
        for i = 1:fix(img_height/8)
            for j = 1:fix(img_width/8)
                img_block8x8 = srcImage(8*(i-1)+1:8*(i-1)+8, 8*(j-1)+1:8*(j-1)+8);
                img_block64 = dct2D(img_block8x8);    %DCT transform
                %quantization part
                img_block64 = round(img_block64./JPEGQuantTable);
%                 img_block64 = img_block64 .* JPEGQuantTable;
%                 iimg_block64 = idct2D(img_block64);
%                 iimg_block64(iimg_block64<0)=0;
%                 iimg_block64(iimg_block64>255)=255;
%                 iimg_block8x8 = reshape(iimg_block64, [8,8])';
%                 procImage(8*(i-1)+1:8*(i-1)+8, 8*(j-1)+1:8*(j-1)+8) = iimg_block8x8;
                procImage(8*(i-1)+1:8*(i-1)+8, 8*(j-1)+1:8*(j-1)+8) = reshape(img_block64, [8,8]);
            end
        end
        procImage = uint8(procImage);
        % imshow(procImage);
    elseif strcmp(src_quant_conf.type, 'custom')
        quant_array = src_quant_conf.quant_array;
        %%customed quantization
        img_width = size(procImage, 2);
        img_height = size(procImage, 1);
        %centroid quantization
        CentroidArray = zeros(1, length(quant_array)+1);
        CentroidCnt = zeros(1, length(quant_array)+1);
        for y=1:img_height
            for x=1:img_width
                img_pixel = srcImage(y,x);
                img_pixel = double(img_pixel);
                if img_pixel<quant_array(1)
                    CentroidArray(1) = CentroidArray(1)+img_pixel;
                    CentroidCnt(1) = CentroidCnt(1)+1;
                end
                for i=1:length(quant_array)-1
                    if img_pixel>=quant_array(i) && img_pixel<quant_array(i+1)
                        CentroidArray(i+1) = CentroidArray(i+1) + img_pixel;
                        CentroidCnt(i+1) = CentroidCnt(i+1)+1;
                    end
                end
                if img_pixel>=quant_array(end)
                    CentroidArray(length(quant_array)+1) = CentroidArray(length(quant_array)+1)+img_pixel;
                    CentroidCnt(length(quant_array)+1) = CentroidCnt(length(quant_array)+1)+1;
                end
            end
        end
        for i =1:length(quant_array)+1
            if CentroidCnt(i) ~= 0
                CentroidArray(i) = round(CentroidArray(i)/CentroidCnt(i));
            end
        end
        huffOri = zeros(1,length(quant_array)+1);
        for y = 1:img_height
            for x = 1:img_width
                img_pixel = srcImage(y,x);
                img_pixel = double(img_pixel);
                if img_pixel < quant_array(1)
                    % centroid quantization
                    img_pixel = CentroidArray(1);   % niu  img_pixel =quant_array(1)/2
                    huffOri(1) = huffOri(1)+1;
                end
                for i = 1: length(quant_array)-1
                    if img_pixel >= quant_array(i) && img_pixel < quant_array(i+1)
                        %centroid quantization 
                        img_pixel = CentroidArray(i+1);  % niu img_pixel = (quant_array(i)+quant_array(i+1))/2
                        huffOri(i+1) = huffOri(i+1)+1;
                    end
                end
                if img_pixel>=quant_array(end)
                    %centroid quantization
                    img_pixel = CentroidArray(length(quant_array)+1); %niu  img_pixel = (255+quant_array(end))/2
                    huffOri(length(quant_array)+1) = huffOri(length(quant_array)+1)+1;
                end
                procImage(y,x) = img_pixel;
            end
        end
        % imshow(procImage);
    end
end

