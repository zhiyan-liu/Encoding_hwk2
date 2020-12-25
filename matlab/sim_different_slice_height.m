%% Setup utilities.
setup_src_quant;
setup_src_vlc;
setup_channel;

addpath('utils/');

%% Load the image.
b_FileStat = false;   
[fileName, pathName] = uigetfile('*');
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

%% Start simulations and record R-D curve.
slice_height_arr = [2, 4, 8, 16, 32];
Ebn0 = 3.5;
N_sh = length(slice_height_arr);
N_sim = 1;
% quant_factor = 10; % Huffman codebook is designed @ quant_factor = 10.
mean_PSNR = zeros(N_sh, 1);
rates = zeros(N_sh, 1);

for sh_idx = 1:N_sh
    temp_src_vlc_conf = src_vlc_conf;
    temp_src_vlc_conf.slice_height = slice_height_arr(sh_idx);
    
    procImage = src_quant(srcImage, src_quant_conf);
    [transmit_bitstream, codebook, height, width] = src_vlc(procImage, temp_src_vlc_conf);
    psnr_arr = zeros(N_sim, 1);
    
    for sim_idx = 1:N_sim
        recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0);
        recImage = src_decode(recv_bitstream, codebook, height, width, temp_src_vlc_conf);
        if strcmp(src_quant_conf.type, 'h.261')
            recImage = h261_inv(recImage, src_quant_conf);
        end
        % isequal(procImage, recImage)
        psnr_arr(sim_idx) = PSNR(srcImage, recImage);
        figure;
        imshow(uint8(recImage));
        pause;
    end
    mean_PSNR(sh_idx) = mean(psnr_arr);
    rates(sh_idx) = length(transmit_bitstream); % Rates are expected to be the same.
end

%% Plot!!
figure;
plot(slice_height_arr, mean_PSNR, '-x');
title('PSNR-Slice Height');
xlabel('Slice height');
ylabel('Average PSNR (dB)');
grid on;

%% Save simulation files.
save('data/sliceheight_single_fixed_codebook.mat');


