 function [codebook_huff] = gen_codebook(X,vlcRadio,pr)
 %X=huffmancoding 
 %vlcRadio=0:1 symbol; vlcRadio=1:2symbol;
 %pr=1:write to txt: onesymbol_coodbook_file  /  twosymbol_coodbook_file
 
 
%  huff0ri=[0 0 34 200 50 820 650 1300 1100 430 0 56 700  43 0 0];
%  e=0.1;
%  vlcRadio=1;
%  pr=1;
%  X=HuffmanCoding(huff0ri,e);
 

 a=length(X);
switch vlcRadio
    case 0     %1 symbol
       codebook_huff=struct('num_1',[],'code_1',"");
       for i=1:1:(a-1)
           codebook_huff.num_1(i)=X{1,i};
           h=string(X{2,i});
           codebook_huff.code_1(i)=h;
       end
       h=string(X{2,a});
       codebook_huff.code_1(a)=h;
       
       if pr==1       %print
            fid=fopen('onesymbol_coodbook_file.txt','wt');
            for k=1:1:a-1
                fprintf(fid,'%d\0',codebook_huff.num_1(k));
                fprintf(fid,'%s\n',codebook_huff.code_1(k));
            end
            fprintf(fid,'%s',codebook_huff.code_1(a));
            fclose(fid);
       end
       
       
    case 1 %2 symbol
        codebook_huff=struct('num_2_1',[],'num_2_2',[],'code_2',"");
        for j=1:1:(a-1)
            codebook_huff.num_2_1(j)=X{1,j}(1);
            codebook_huff.num_2_2(j)=X{1,j}(2);
            h=string(X{2,j});
            codebook_huff.code_2(j)=h;
        end
        h=string(X{2,a});
        codebook_huff.code_2(a)=h;
        
        if pr==1       %print
            fid=fopen('twosymbol_coodbook_file.txt','wt');
            for k=1:1:a-1
                fprintf(fid,'%d\0',codebook_huff.num_2_1(k));
                fprintf(fid,'%d\0',codebook_huff.num_2_2(k));
                fprintf(fid,'%s\n',codebook_huff.code_2(k));
            end
            fprintf(fid,'%s',codebook_huff.code_2(a));
            fclose(fid);
       end 
end

end

