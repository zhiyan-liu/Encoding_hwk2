function [recImage] = src_decode(bitstream, codebook, height, width, src_vlc_conf)
    if strcmp(src_vlc_conf.num_symbols, 'single')
        recImage = one_symbol_decode(bitstream, codebook, src_vlc_conf.slice_height, ...
    height, width, src_vlc_conf.slice_start_code);
    elseif strcmp(src_vlc_conf.num_symbols, 'double')
        recImage = two_symbol_decode(bitstream, codebook, src_vlc_conf.slice_height, ...
    height, width, src_vlc_conf.slice_start_code);
    end
end

