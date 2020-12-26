%% Setup utilities.
clear;
setup_src_quant;
setup_src_vlc;
setup_channel;

addpath('utils/');

%% Load the image.
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
Epn0 = 50;                  % 50dB.
quant_factors_arr = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65];

N_qf = length(quant_factors_arr);
N_sim = 250;
% quant_factor = 10; % Huffman codebook is designed @ quant_factor = 10.
mean_PSNR = zeros(N_qf, 2);
rates = zeros(N_qf, 1);

cnt_configs = 2;
sim_src_quant_conf(1) = src_quant_conf;
sim_src_quant_conf(2) = src_quant_conf;
sim_src_quant_conf(2).type = 'h.261';
sim_src_quant_conf(2).factor = 10;          % will be modified.


%% Simulation Loop
for config_idx = 1:cnt_configs
    temp_src_quant_conf = sim_src_quant_conf(config_idx);
    for qf_idx = 1:N_qf
        qf = quant_factors_arr(qf_idx);
        if config_idx == 1
            temp_src_quant_conf.step = qf;
        elseif config_idx == 2
            temp_src_quant_conf.factor = qf;
        end
        
        procImage = src_quant(srcImage, temp_src_quant_conf);                               % Quantization.
        [transmit_bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf);   % Source Encode.
        psnr_arr = zeros(N_sim, 1);
        Ebn0 = Epn0 - 10*log10(length(transmit_bitstream)); % Energy per bit w.r.t. noise.

        parfor sim_idx = 1:N_sim
            recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0);
            recImage = src_decode(recv_bitstream, codebook, height, width, src_vlc_conf);
            if strcmp(temp_src_quant_conf.type, 'h.261')
                recImage = h261_inv(recImage, temp_src_quant_conf);
            end
            % isequal(procImage, recImage)
            psnr_arr(sim_idx) = PSNR(srcImage, recImage);
%             figure;
%             imshow(uint8(recImage));
%             pause;
        end
        mean_PSNR(qf_idx, config_idx) = mean(psnr_arr);
        rates(qf_idx) = length(transmit_bitstream); % Rates are expected to be the same.
    end
end

%% Plot!!
figure;
plot(quant_factors_arr, mean_PSNR(:,1), '-x');
hold on;
plot(quant_factors_arr, mean_PSNR(:,2), '-o');
title('PSNR-Quantization Factor(QF) curve');
xlabel('QF');
ylabel('Average PSNR (dB)');
grid on;

%% Save simulation files.
save('data/QF.mat');




