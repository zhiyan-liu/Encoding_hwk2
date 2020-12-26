function recv_bitstream = channel_transmit(transmit_bitstream, channel_conf, Ebn0)
    % Assume that input "transmit_bitstream" is a row vector of booleans.
    L = length(transmit_bitstream);

    % BPSK modulation employed.
    encoder_type = channel_conf.encoder_type;
    if strcmp(encoder_type, 'none')
        sigma = 1/sqrt(2)*(10^(-Ebn0/20));
        channel_bits_BPSK_transmit = 1-2*transmit_bitstream;
        channel_bits_BPSK_recv = channel_bits_BPSK_transmit + sigma * randn(size(transmit_bitstream));
        recv_bitstream = (channel_bits_BPSK_recv<0);

    elseif strcmp(encoder_type, 'conv')
        conv_encoder_conf = channel_conf.encoder_conf;
        channel_bits = conv_encode(transmit_bitstream, conv_encoder_conf);

        % calculate sigma using equation: sigma = 1/sqrt(2R) * 10^(-Ebn0/20).
        R = L/length(channel_bits);
        sigma = 1/sqrt(2*R)*(10^(-Ebn0/20));
        channel_bits_BPSK_transmit = 1-2*channel_bits;
        channel_bits_BPSK_recv = channel_bits_BPSK_transmit + sigma * randn(size(channel_bits));
        % convert into L2-measures.
        
        if conv_encoder_conf.n == 2
            temp = channel_bits_BPSK_recv(1:2:end) + 1j*channel_bits_BPSK_recv(2:2:end);
            constellation = [1+1j; 1-1j; -1+1j; -1-1j];
            L2_soft_metrics = abs(temp-constellation).^2;
        elseif conv_encoder_conf.n == 3
            % Rate = 1/3.
            L_ch = length(channel_bits);
            assert(mod(L_ch, 3) == 0);
            dim3_constellation =   [1, 1, 1;...
                                    1, 1, -1;...
                                    1, -1, 1;...
                                    1, -1, -1;...
                                    -1, 1, 1;...
                                    -1, 1, -1;...
                                    -1, -1, 1;...
                                    -1, -1, -1];
            temp = reshape(channel_bits_BPSK_recv, [3, L_ch/3]);
            L2_soft_metrics = zeros(2^3, L_ch/3);
            for idx_col = 1:L_ch/3
                three_bits_BPSK = temp(:,idx_col).';
                L2_soft_metrics(:, idx_col) = sum((dim3_constellation - three_bits_BPSK).^2,2);
            end                    
        end
        recv_bitstream = fast_conv_decode(L2_soft_metrics, conv_encoder_conf, true);
    end
end