function dump_codebook(codebook_struct, filename)
    if isfield(codebook_struct, 'code_1')
        single_symbol = true;
    else
        single_symbol = false;
    end
    
    if ~exist('filename', 'var') || isempty(filename)
        if single_symbol
            filename = 'single_sym_codebook.txt';
        else
            filename = 'double_sym_codebook.txt';
        end
    end
    
    % dump codebook!
    if single_symbol
        L = length(codebook_struct.num_1);
        fid=fopen(filename,'wt');

        for k=1:L
            fprintf(fid, '%d %s\n', codebook_struct.num_1(k),...
                codebook_struct.code_1(k));
        end
        fprintf(fid,'%s',codebook_struct.code_1(L+1));  % escape
        fclose(fid);
    else
        L = length(codebook_struct.num_2_1);
        fid=fopen(filename,'wt');
        
        for k=1:L
            fprintf(fid, '%d %d %s\n', codebook_struct.num_2_1(k),...
                codebook_struct.num_2_2(k),...
                codebook_struct.code_2(k));
        end
        fprintf(fid,'%s',codebook_struct.code_2(L+1));
        fclose(fid);
    end
end