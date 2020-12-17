% % % % % % % % % % % % % % % % % % % % % % 
% Author:Ziwei Wei, Benben Niu
% E-mail: weizw18@mails.tsinghua.edu.cn
%
%New phases added by Junyou Chen by Nov2015;
%   Quantization, Inverse Quantization, DCT, IDCT, Huffman Coding, VLC
%Revised by Benben Niu by Nov. 2016;
%   Slice-related VLC
%Revised by Benben Niu by Sep. 2018;
%   Noise Level, Iterations
%Revised by Ziwei Wei by Aug. 2020
%   software transportation to MATLAB platform
%
%   Copyright (c) 2020, VISUAL COMMUNICATION LAB. EE DEPARTMENT, TSINGHUA UNIVERSITY. All rights reserved.   
%   Note: Redistribution and use in source and binary forms, with or without modification, are permitted only 
%   for "The Introduction to Coding" course of EE Department, Tsinghua University. The following conditions are required to
%   be met:
%        *The name of VISUAL COMMUNICATION LAB. EE DEPARTMENT, TSINGHUA UNIVERSITY may not be used to endorse or 
%          promote products derived from this software without specific prior written permission.
% % % % % % % % % % % % % % % % % % % % % % 

function recImage = one_symbol_decode(bitstream, codebook, slice_height, ...
    height, width, slice_start_code)
    num_1 = codebook.num_1;
    code_1 = codebook.code_1;
    data = '';
    data(bitstream >= 0) = '0';
    data(bitstream == 1) = '1';

    maxCodeLength = 0;
    escapeLength = length(char(code_1(end)));  % length of escape code
    for i=1:length(code_1)
        if length(char(code_1(i)))>maxCodeLength
            maxCodeLength = length(char(code_1(i)));
        end
    end
    if slice_height == 1
        slice_height = height;
    end
    
    slice_idx = 0;
    disable = false;
    current = 1;
    slice_err = true;   % slice idx in boundary
    done = false;   % current bit has been decode.
    complete = false;
    nowx = 1;   %cordinate on each slice
    nowy = 1;
    
    recImage = zeros(height, width);
    
    while current <= length(data)
        if length(data)-current < 23
            header_temp = data(current:end);
        else
            header_temp = data(current:current+23);
        end
        if isequal(header_temp,slice_start_code)
            current = current+24;   %header
            slice_idx= bin2dec(data(current:current+7));
            current = current+8;    %slice number
            nowx = 1;   % at the sliceheader, nowx and nowy init.
            nowy = 1;
            done= true; % code in slice header
            if slice_idx<fix(height/slice_height)  % start from 0 in encoder
                slice_err = false;
            else
                slice_err = true;
            end
            fprintf("One symbol decode:\t slice_idx:%d\n",slice_idx);
        elseif ~slice_err   % bit not in slice header
            done = false;
            disable = false;
            for i = 1:maxCodeLength   %get the max length of codebook bits from bitstream to test the pixel is code by codebook
                if current + i-1 > length(data)
                    fprintf("One symbol decode:\t Error1! No enough bits!");
                    return;
                    
                end
                tmp = data(current:current+i-1);
                for j=1:length(num_1)   % compared with the codebook first
                    if code_1(j)==tmp  %bits in codebook
                        disable = false;  % not escapecode+pix(8 bit)
                        for m_1=1:i-1
                            if length(data)-current-m_1 < 23
                                header_temp = data(current+m_1:end);
                            else
                                header_temp = data(current+m_1:current+m_1+23);
                            end
                            %                                     header_temp = data(current+m_1:current+m_1+23);
                            if isequal(header_temp,slice_start_code)
                                disable = true;
                                current = current + m_1+24;
                                slice_idx = bin2dec(data(current:current+7));
                                current = current+8;
                                nowx = 1;
                                nowy = 1;
                                done = true;
                                break;
                            end
                        end
                        
                        if ~disable     % bits in codebook and get the pix in num_1
                            recImage(slice_idx*slice_height+nowy, nowx) = num_1(j);
                            current = current+i;
                            done = true;
                            break;
                        end
                    end
                end
                if done
                    break;
                end
            end
            if ~disable && ~done     %escapecode+pix  or pix on codebook
                if(current+escapeLength-1)>length(data)
                    fprintf("One symbol decode:\t Error2! No enough bits!\n");
                    return;
                end
                tmp = data(current:current+escapeLength-1);
                if tmp == code_1(end)   % escape code
                    for m_escapecode = 1:escapeLength-1
                        if length(data)-current-m_escapecode < 23
                            header_temp = data(current+m_escapecode:end);
                        else
                            header_temp = data(current+m_escapecode:current+m_escapecode+23);
                        end
                        %                                 header_tmp = data(current+m_escapecode:current+m_escapecode+23);
                        if isequal(header_temp,slice_start_code)
                            disable = true;
                            current = current+m_escapecode+24;
                            slice_idx = bin2dec(data(current:current+7));
                            current = current+8;
                            nowx = 1;
                            nowy = 1;
                            done = true;
                            break;
                        end
                    end
                    
                    if ~disable   % code = escapecode+pix(8 bit)
                        current = current+escapeLength;
                        if (current+7) > length(data)   % pix 8 bit,to test whether out of boundary
                            fprintf("One symbol decode:\t Error3! No enough bits! \tPSNR:%f\n");
                            return;
                        end
                        
                        for m_header=1:7  % pix in 8 bit
                            if length(data)-current-m_header < 23
                                header_temp = data(current+m_header:end);
                            else
                                header_temp = data(current+m_header:current+m_header+23);
                            end
                            %                                     header_temp = data(current+m_header:current+m_header+23);
                            if isequal(header_temp,slice_start_code)
                                disable = true;
                                current = current+m_header+24;
                                slice_idx = bin2dec(data(current:current+7));
                                current = current+8;
                                nowx = 1;
                                nowy = 1;
                                done = true;
                                break;
                            end
                        end
                        
                        if ~disable  % pix in 8 bit
                            tmp = data(current: current+7);
                            current = current+8;
                            para = bin2dec(tmp);
                            recImage(slice_idx*slice_height+nowy, nowx) = para;
                            done = true;
                        end
                    end
                else
                    slice_err = true;
                end
            end
            
            if (~disable) && done && (~slice_err)   % update nowx/nowy
                if nowx == width
                    if (slice_idx*slice_height+nowy)==height
                        if current <= length(data)  % redundant bits
                            fprintf("One symbol decode:\t Error4! Too many bits! \tPSNR:%f\n");
                            return;
                        else
                            complete = true;
                        end
                        %to avoid nowx, nowy out of boundary
                    elseif nowy == slice_height
                        slice_err = true;
                    else
                        nowy = nowy+1;
                        nowx = 1;
                    end
                else
                    nowx = nowx+1;
                end
            end
        else
            current = current+1;
        end
    end
    
    if (~complete&&(current==length(data)))&&(((slice_idx*slice_height+nowy)*width+nowx+1)<=height*width)
        fprintf("One symbol decode:\t Error5! No enough bits!");
        return;
    end
    
    figure('name', 'Rec Image', 'NumberTitle', 'off');
    imshow(recImage,[]);
    
    if complete
        fprintf("Reconstruction completed!\n");
    else
        fprintf("One symbol decode:\t Reconstruction failed!\n");
        return;
    end
end

