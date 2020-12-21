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

function recImage= two_symbol_decode(bitstream, codebook, slice_height, ...
    height, width, slice_start_code)

    num_2_1 = codebook.num_2_1;
    num_2_2 = codebook.num_2_2;
    code_2 = codebook.code_2;
    data = '';
    data(bitstream >= 0) = '0';
    data(bitstream == 1) = '1';
    
    complete = false;
    maxCodeLength = 0;
    escapeLength = length(char(code_2(end))); % length of escape code
    for i=1:length(code_2)
        if length(char(code_2(i)))>maxCodeLength
            maxCodeLength = length(char(code_2(i)));
        end
    end
    
    if slice_height == 1
        slice_height = height;
    end
    
    slice_idx = 0;
    disable = false;
    current = 1;
    slice_err = true;
    done = false;
    nowx = 1;   %%%%%!!!!!! 1
    nowy = 1;
    
    recImage = zeros(height, width);   %initialize recImage
    
    while current <= length(data)
        if length(data)-current < 23
            header_temp = data(current:end);
        else
            header_temp = data(current:current+23);
        end
        %                 header_temp = data(current:current+23);
        if isequal(header_temp,slice_start_code)
            current = current+24;   %header
            slice_idx = bin2dec(data(current:current+7));
            current = current+8;    %slice number
            nowx = 1;
            nowy = 1;
            done= true;
            if slice_idx<fix(height/slice_height)
                slice_err = false;
            else
                slice_err = true;
            end
            fprintf("Two symbol decode:\tslice_idx:%d\n",slice_idx);
        elseif ~slice_err
            done = false;
            disable = false;
            for i = 1:maxCodeLength
                if current + i-1 > length(data)
                    fprintf("Two symbol decode:\t Error1! No enough bits!\n");
                    return;
                end
                tmp = data(current:current+i-1);
                for j=1:length(num_2_1)
                    if code_2(j)==tmp
                        disable = false;
                        for m_1=1:i-1
                            if length(data)-current-m_1 < 23
                                header_temp = data(current+m_1:end);
                            else
                                header_temp = data(current+m_1:current+m_1+23);
                            end
                            %                                     header_temp = data(current+m_1:current+m_1+24);
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
                        
                        if ~disable
                            recImage(slice_idx*slice_height+nowy, nowx) = num_2_1(j);
                            recImage(slice_idx*slice_height+nowy, nowx+1) = num_2_2(j);
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
            
            if ~disable && ~done
                if(current+escapeLength-1)>length(data)
                    fprintf("Two symbol decode:\tError2! No enough bits!n");
                    return;
                    
                end
                
                tmp = data(current:current+escapeLength-1);
                if tmp == code_2(end)
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
                    
                    if ~disable
                        current = current+escapeLength;
                        if (current+15) > length(data)
                            fprintf("Two symbol decode:\tError3! No enough bits!\n");
                            return;
                            
                        end
                        
                        for m_header=1:15
                            if length(data)-current-m_header < 23
                                header_temp = data(current+m_header:end);
                            else
                                header_temp = data(current+m_header:current+m_header+23);
                            end
                            %                                     header_temp = data(current+m_header:current+m_header+24);
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
                        
                        if ~disable
                            tmp = data(current : current+7);
                            current = current+8;
                            para = bin2dec(tmp);
                            recImage(slice_idx*slice_height+nowy, nowx) = para;
                            tmp = data(current: current+7);
                            current = current+8;
                            para = bin2dec(tmp);
                            recImage(slice_idx*slice_height+nowy, nowx+1) = para;
                            done = true;
                        end
                    end
                else
                    slice_err = true;
                end
            end
            
            if (~disable) && done && (~slice_err)
                if nowx == width-1
                    if (slice_idx*slice_height+nowy)==height
                        if current <= length(data)
                            fprintf("Two symbol decode:\tError4! Too many bits!\n");
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
                    nowx = nowx+2;
                end
            end
        else
            current = current+1;
        end
    end
    
    if (~complete&&(current==length(data)))&&(((slice_idx*slice_height+nowy)*width+nowx+2)<=height*width)
        fprintf("Two symbol decode:\tError5! No enough bits!\n");
        return;
    end
    
    % figure('name', 'Rec Image', 'NumberTitle', 'off');
    % imshow(recImage,[]);
    
    if complete
        disp("Reconstruction completed!\n");
    else
        disp("Two symbol decode:\tReconstruction failed!");
        return;
    end
end

