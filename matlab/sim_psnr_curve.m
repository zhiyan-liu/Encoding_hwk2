%% Setup utilities.
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

%% Start simulations and record R-D curve.
Ebn0 = 2;   % in dB.
N_sim = 10;
quant_step_arr = [4, 8, 10, 15, 20, 25, 30, 40];
N_rates = length(quant_step_arr);
mean_PSNR = zeros(N_rates, 1);
rates = zeros(N_rates, 1);          % cnt. of encoded bits.

for r_idx = 1:N_rates
    temp_src_quant_conf = src_quant_conf;
    temp_src_quant_conf.step = quant_step_arr(r_idx);
    
    procImage = src_quant(srcImage, temp_src_quant_conf);
    [transmit_bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf);
    psnr_arr = zeros(N_sim, 1);
    
    parfor sim_idx = 1:N_sim
        recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0);
        recImage = src_decode(recv_bitstream, codebook, height, width, src_vlc_conf);
        % isequal(procImage, recImage)
        psnr_arr(sim_idx) = PSNR(srcImage, recImage);
    end
    mean_PSNR(r_idx) = mean(psnr_arr);
    rates(r_idx) = length(transmit_bitstream);
end

%% Plot!!
