src_vlc_conf.num_symbols = 'double';    % 'single', 'double'
src_vlc_conf.codebook_type = 'fixed';   % 'fixed', 'by-case'
src_vlc_conf.slice_height = 4;
src_vlc_conf.slice_start_code = '111111110000000011111111';


if strcmp(src_vlc_conf.codebook_type, 'fixed')
    if strcmp(src_vlc_conf.num_symbols, 'single')
        src_vlc_conf.codebook_filename = 'single_sym_codebook.txt';
    else
        src_vlc_conf.codebook_filename = 'double_sym_codebook.txt';
    end
end