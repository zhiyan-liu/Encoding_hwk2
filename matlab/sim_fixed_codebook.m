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
Ebn0_arr = [2, 3, 4, 6, 8, 10];
N_ebn0 = length(Ebn0_arr);
N_sim = 150;
% quant_factor = 10; % Huffman codebook is designed @ quant_factor = 10.
mean_PSNR = zeros(N_ebn0, 1);
rates = zeros(N_ebn0, 1);

for eb_idx = 1:N_ebn0
    procImage = src_quant(srcImage, src_quant_conf);
    [transmit_bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf);
    psnr_arr = zeros(N_sim, 1);
    Ebn0 = Ebn0_arr(eb_idx);
    
    parfor sim_idx = 1:N_sim
        recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0);
        recImage = src_decode(recv_bitstream, codebook, height, width, src_vlc_conf);
        if strcmp(src_quant_conf.type, 'h.261')
            recImage = h261_inv(recImage, src_quant_conf);
        end
        % isequal(procImage, recImage)
        psnr_arr(sim_idx) = PSNR(srcImage, recImage);
    end
    mean_PSNR(eb_idx) = mean(psnr_arr);
    rates(eb_idx) = length(transmit_bitstream); % Rates are expected to be the same.
end

%% Plot!!
figure;
plot(Ebn0_arr, mean_PSNR, '-x');
title(strcat('PSNR-Ebn0 curve @ R = ',num2str(rates(1)/1000),'kbit'));
xlabel('Bit SNR E_b/n_0 (dB)');
ylabel('Average PSNR (dB)');
grid on;

%% Save simulation files.
save(strcat('data/quantfactor_',num2str(src_quant_conf.step),'_fixed_codebook.mat'));




