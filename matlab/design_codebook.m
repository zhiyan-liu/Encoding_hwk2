%% Step1: Load all the available pictures.
selpath = uigetdir;
dir_info = dir(selpath);
imgs_filename = cell(1,1);
cnt_imgs = 0;
for k = 1:length(dir_info)
    if ~dir_info(k).isdir
        [~,~,ext] = fileparts(dir_info(k).name);
        if strcmp(ext, '.bmp') || strcmp(ext, '.jpg') || strcmp(ext, '.png')
            cnt_imgs = cnt_imgs + 1;
            imgs_filename{cnt_imgs} = dir_info(k).name;
        end
    end
end

images_cell = cell(cnt_imgs, 1);
for k = 1:cnt_imgs
    srcImage = imread([selpath,'\', imgs_filename{k}]);
    infoSrcImage = imfinfo([selpath, '\', imgs_filename{k}]);
    if infoSrcImage.ColorType == "truecolor"
        srcImage = rgb2gray(srcImage);
    end
    images_cell{k} = srcImage;
end


%% Step2: Count the pixel frequencies and prepare for 2-syms VLC coding.
setup_src_quant;
setup_src_vlc;
images_quantized = cell(cnt_imgs, 1);
value_list = [];
L = 0;

if strcmp(src_vlc_conf.num_symbols, 'double')
    for k = 1:cnt_imgs
        images_quantized{k} = src_quant(images_cell{k}, src_quant_conf);
        temp = unique(images_quantized{k}(1:end));
        value_list = unique([value_list, temp]);
        L = L + numel(images_quantized{k})/2;
    end

    n = length(value_list);
    N = n ^ 2;                  % two-sym statistics.

    symbol_list = cell(1,N);
    prob_list = zeros(1,N);

    for k = 1:cnt_imgs
        image = images_quantized{k};
        width = size(image, 2);
        odd_cols = image(:,1:2:width);
        even_cols = image(:,2:2:width);
        for x = 1:n
            for y = 1:n
                symbol_list{n*x+y-n} = [value_list(x), value_list(y)];
                prob_list(n*x+y-n) = prob_list(n*x+y-n) + ...
                    sum(sum((odd_cols==value_list(x)) & (even_cols == value_list(y))))/L;
            end
        end
    end
    symbol_list(prob_list == 0) = [];
    prob_list(prob_list == 0) = [];
else
    % single-symbol case.
    for k = 1:cnt_imgs
        images_quantized{k} = src_quant(images_cell{k}, src_quant_conf);
        temp = unique(images_quantized{k}(1:end));
        value_list = unique([value_list, temp]);
        L = L + numel(images_quantized{k});
    end
    N = length(value_list);
    symbol_list = cell(1,N);
    prob_list = zeros(1,N);
    
    for k = 1:cnt_imgs
        image = images_quantized{k};
        width = size(image, 2);
        for idx = 1:N
            symbol_list{idx} = value_list(idx);
            prob_list(idx) = prob_list(idx) + sum(sum(image==value_list(idx)))/L;
        end
    end
    symbol_list(prob_list==0) = [];
    prob_list(prob_list==0) = [];
end

%% Step3: Perform huffman coding and dump the codebook.
escape_thres = 3*min(prob_list);
huffman_info = huffman_coding(symbol_list,prob_list,escape_thres);
if strcmp(src_vlc_conf.num_symbols, 'double') 
    codebook = gen_codebook(huffman_info, 1, 0);
    dump_codebook(codebook);
else
    codebook = gen_codebook(huffman_info, 0, 0);
    dump_codebook(codebook);
end

disp('Codebook dumped!');

