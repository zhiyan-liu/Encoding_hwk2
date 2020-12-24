%% Setup utilities.
setup_src_quant;
setup_src_vlc;
setup_channel;

addpath('utils/');

%% Read the image.
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

if infoSrcImage.ColorType == "truecolor"
    srcImage = rgb2gray(srcImage);
end

%% Generate codebook according to the huffman encoder.
% uniform quantization, step=10.
procImage = src_quant(srcImage, src_quant_conf);
[transmit_bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf);

%% Dump codebook to file.
dump_codebook(codebook);
disp('Codebook dumped!');




