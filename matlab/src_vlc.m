function [bitstream, codebook, height, width] = src_vlc(procImage, src_vlc_conf)
    width = size(procImage,2);
    height = size(procImage,1);
    slice_height = src_vlc_conf.slice_height;
    slice_start_code = src_vlc_conf.slice_start_code;
    if strcmp(src_vlc_conf.num_symbols, 'single')
        % Prepare codebook
        if strcmp(src_vlc_conf.codebook_type, 'fixed')
            filename = src_vlc_conf.codebook_filename;
            num_1 = [];
            code_1 = [];
            fid = fopen(filename, 'r');   %read .txt file line-by-line
            while ~feof(fid)
                str = fgetl(fid); 
                str_split = regexp(str, '\s+', 'split');  
                if  length(str_split)==1
                    code_1 = [code_1 str_split{1}];
                    break;
                else
                    num_1 = [num_1 str2num(str_split{1})];
                    code_1 = [code_1 string(str_split{2})];
                end
            end
            if length(num_1) ~= length(code_1)-1
                fprintf("One symbol encode:\t Table uncompleted!");
                return;
            end
            fclose(fid);
        elseif strcmp(src_vlc_conf.codebook_type, 'by-case')
            % TODO: Prepare the codebook from procImage using Huffman coding 
        end
        % Return codebook for de-VLC use
        codebook.num_1 = num_1;
        codebook.code_1 = code_1;
        % Perform VLC coding according to codebook
        bin_file = fopen('bin.txt', 'wb');
        for y=1:size(procImage, 1)   %height
            if (mod(y,slice_height)==1)
                % This character '0' is used to fill in the space in fields when generating text
                fwrite(bin_file, slice_start_code, 'uint8');    % !!!!!!×¢ÒâÊÇ·ñÌî³ä0
                fwrite(bin_file, dec2bin((y-1)/slice_height,8), 'uint8');
            end
            for x = 1:size(procImage, 2) %width
                pix = procImage(y,x);
                if ismember(pix, num_1)     % pix in num_1, encode corresponding code in code_1, otherwise, encode escapecode and pix
                    fwrite(bin_file, code_1(find(num_1==pix)), 'uint8');
                else
                    fwrite(bin_file, code_1(end), 'uint8');
                    fwrite(bin_file, dec2bin(pix,8), 'uint8');
                end
            end
        end
        fclose(bin_file);
        
        % calculate the cost of transmitting codebook
        length_table = 0;
        for m=1:length(num_1)
            length_table = length_table+length(char(code_1(m)));
            length_table = length_table+length(dec2bin(num_1(m)));
        end
        codebook.length_table = length_table+length(char(code_1(end)));
        
    elseif strcmp(src_vlc_conf.num_symbols, 'double')
        % Prepare codebook
        if strcmp(src_vlc_conf.codebook_type, 'fixed')
            filename = src_vlc_conf.codebook_filename;
            num_2_1 = [];
            num_2_2 = [];
            code_2 = [];

            fid = fopen(filename, 'r');   %read .txt file line-by-line
            if isempty(fid)
                disp("Two symbol encode:\tNo file open!");
            end
            while ~feof(fid)
                str = fgetl(fid);
                str_split = regexp(str, '\s+', 'split');
                if length(str_split) ~=1 && length(str_split) ~=3
                    disp("Two symbol encode:\tInvalid table!");
                elseif length(str_split)==1
                    code_2 = [code_2 str_split{1}];
                    break;
                else
                    num_2_1 = [num_2_1 str2num(str_split{1})];
                    num_2_2 = [num_2_2 str2num(str_split{2})];
                    code_2 = [code_2 string(str_split{3})];
                end
            end
            if length(num_2_1) ~= length(code_2)-1
                disp("Two symbol encode:\tTable uncompleted!");
                return;
            end
            fclose(fid);
        elseif strcmp(src_vlc_conf.codebook_type, 'by-case')
            % TODO: Prepare the codebook from procImage using Huffman coding 
        end
        % Return codebook for de-VLC use
        codebook.num_2_1 = num_2_1;
        codebook.num_2_2 = num_2_2;
        codebook.code_2 = code_2;
        % Perform VLC coding according to codebook
        bin_file = fopen('bin.txt', 'wb');
        for y=1:size(procImage, 1)   %height
            if (mod(y,slice_height)==1)
                % This character '0' is used to fill in the space in fields when generating text
                fwrite(bin_file, slice_start_code, 'uint8');    % !!!!!!×¢ÒâÊÇ·ñÌî³ä0
                fwrite(bin_file, dec2bin((y-1)/slice_height,8), 'uint8');
            end
            for x = 1:size(procImage, 2)/2 %width
                pix1 = procImage(y, 2*x-1);
                pix2 = procImage(y, 2*x);
                if ismember(pix1, num_2_1) && isequal(pix2,num_2_2(find(num_2_1==pix1)))
    %                 fprintf("x:%d\ta:%d\n",x,find(num_2_1==pix1));
                    fwrite(bin_file, code_2(find(num_2_1==pix1)), 'uint8');
                else
                    fwrite(bin_file, code_2(end), 'uint8');
                    fwrite(bin_file, dec2bin(pix1,8), 'uint8');
                    fwrite(bin_file, dec2bin(pix2,8), 'uint8');
                end
            end
        end
        fclose(bin_file);

        % calculate the cost of transmitting codebook
        length_table = 0;
        for m=1:length(num_2_1)
            length_table = length_table+length(char(code_2(m)));
            length_table = length_table+length(dec2bin(num_2_1(m)));
            length_table = length_table+length(dec2bin(num_2_2(m)));
        end
    end
    
    % Get bitstream from bin.txt
    bin_file = fopen('bin.txt', 'r');
    data = fgetl(bin_file);
    bitstream = data == '1';
    fclose(bin_file);
end

