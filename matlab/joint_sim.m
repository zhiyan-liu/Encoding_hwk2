setup_src_quant;
setup_src_vlc;
setup_channel;

b_FileStat = false;   %indicate whether the file is load correctly or not
[fileName, pathName] = uigetfile('*');  %load the image via GUI
srcImage = imread(strcat(pathName, fileName));
infoSrcImage = imfinfo(strcat(pathName, fileName));
if ~isempty(srcImage)
    srcImgBits = infoSrcImage.Width*infoSrcImage.Height*infoSrcImage.BitDepth; %bits of the input image
    fprintf("input image bit:%d\n",srcImgBits);
else
    fprintf("Input image load error!!\n");
    return;
end

%initialize gray table

%transformat if needed
%input image is restricted only for bmp format, thr judge below is u 
if infoSrcImage.ColorType == "truecolor"
    srcImage = rgb2gray(srcImage);
end

procImage = src_quant(srcImage, src_quant_conf);
[transmit_bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf);

Ebn0 = 1;   % in dB.
recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0);

recImage = src_decode(recv_bitstream, codebook, height, width, src_vlc_conf);

isequal(procImage, recImage)

PSNR(srcImage,recImage)