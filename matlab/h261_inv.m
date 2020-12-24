function [recImage] = h261_inv(procImage, src_quant_conf)
recImage = zeros(size(procImage));
procImage = double(procImage) - 128;
quant_factor = src_quant_conf.factor;
JPEGQuantTableOri = [ %JPEG quantization table for luma
    16,11,10,16,24,40,51,61,12,12,14,19,26,58,60,55, ...
    14,13,16,24,40,57,69,56,14,17,22,29,51,87,80,62, ...
    18,22,37,56,68,109,103,77,24,35,55,64,81,104,113,92,...
    49,64,78,87,103,121,120,101,72,92,95,98,112,100,103,99
    ]';
JPEGQuantTable =double( round(JPEGQuantTableOri.*quant_factor./10));
img_width = size(procImage, 2);
img_height = size(procImage, 1);
for i = 1:fix(img_height/8)
    for j = 1:fix(img_width/8)
        img_block8x8 = procImage(8*(i-1)+1:8*(i-1)+8, 8*(j-1)+1:8*(j-1)+8);
        img_block64 = reshape(img_block8x8,[64,1]);
        img_block64 = img_block64 .* JPEGQuantTable;
        iimg_block64 = idct2D(img_block64);
        iimg_block64(find(iimg_block64<0))=0;
        iimg_block64(find(iimg_block64>255))=255;
        iimg_block8x8 = reshape(iimg_block64, [8,8])';
        recImage(8*(i-1)+1:8*(i-1)+8, 8*(j-1)+1:8*(j-1)+8) = iimg_block8x8;
    end
end
recImage = uint8(recImage);
end

