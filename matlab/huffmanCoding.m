function X = huffmanCoding(symbol_list, prob_list, e)

    sum=0;
    probability_sum=0;
    len=length(prob_list);
    Op_List=prob_list;
    
    for k=1:len
        sum=sum+Op_List(k);
    end
    for l=1:len
        Op_List(l)=Op_List(l)/sum;
    end
    [Op_List,ix]=sort(Op_List,'descend');
    for m=len:-1:1  
        if Op_List(m)<e
            probability_sum=probability_sum+Op_List(m);
        end
        if Op_List(m)>=e
            break;
        end
    end
    Op_List_new=[Op_List(1:m) probability_sum];
    len_new=length(Op_List_new);

    Map=[];
    for i=1:len_new-1
        Map=[Map;blanks(len_new)]; 
    end

    for i=1:len_new-1
        [Op_List_new,e]=sort(Op_List_new);

        Map(i,e(1))='1';
        Map(i,e(2))='0';
        Op_List_new(2)=Op_List_new(1)+Op_List_new(2);
        Op_List_new(1)=len_new;
        
        Back_List=zeros(1,len_new);
        for j=1:len_new
            Back_List(e(j))=Op_List_new(j);
        end
        Op_List_new= Back_List; 
    end

    x=len_new;y=len_new-1;
    for i=y:-1:1
        for j=1:x
            if Map(i,j)~=' '
                for k=i-1:-1:1
                    if Map(k,j)~=' '
                        for b=1:x
                            if b~=j && Map(k,b)~=' '
                                Map(k+1:y,b)=Map(k+1:y,j);
                            end
                        end
                    end
                end
            end
        end
    end

    X=cell(2,len_new);
    for j=1:len_new-1
        bit_stream=[];
        X{1,j}=symbol_list{ix(j)};
        for i=y:-1:1
           if Map(i,j)~=' '
               a=Map(i,j);
               bit_stream=[bit_stream,a];
           end
        end
        X{2,j}=bit_stream;
    end
    for j=len_new
        bit_stream=[];
        for i=y:-1:1
           if Map(i,j)~=' '
               a=Map(i,j);
               bit_stream=[bit_stream,a];
           end
        end
        X{2,j}=bit_stream;
    end

end
