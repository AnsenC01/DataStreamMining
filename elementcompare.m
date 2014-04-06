function elementcompare

read_filename1 = 'dataset/batch_data_segment/topics_data1/update_vsm/1.txt';
read_filename2 = 'dataset/general_ksvd/topics_data1/error/XXX.xlsx';
dictionary_filename = 'dataset/general_ksvd/topics_data1/�ֵ�.txt';

thresh = 10;

D = load(dictionary_filename);
data = load(read_filename1);

M_sample = 50;  % ����ά��
L = size(data, 2);  % ԭʼ����ά��
Q = sqrt(M_sample) * normrnd(0,1,M_sample, L);
printf('���������ά�ȣ�%d * %d', size(Q, 1), size(Q, 2));

data1 = Q * data';
data = data';

D1 = Q * D;
Gamma = OMP(D1, data1, thresh);    % ������OMPЧ����һ���ģ����������2��������
%Gamma = omp(D1' * data1, D1' * D1, thresh, ompparams{:});
this_error = compute_err(D, Gamma, data);

printf('������ϣ��в�%f\n', this_error);


%% �Ƚ�
X1 = xlsread(read_filename2);
compare_matrix = zeros(size(data, 1), size(data, 2));
count = 0;
for i = 1 : size(data, 1)
    for j = i : size(data, 2)
        if data(i, j) ~= X1(i, j)
            compare_matrix(i, j) = 1;
            count = count + 1;
        end
    end
end
printf('����Ԫ�ظ�����%d', count);
xlswrite('dataset/general_ksvd/topics_data1/error/1.xlsx', data);
xlswrite('dataset/general_ksvd/topics_data1/error/compare.xlsx', compare_matrix);

end

%% ����в� %%
function err = compute_err(D, Gamma, data)
% ����ϡ������ƵĲв����
err = sqrt(sum(reperror2(data, D, Gamma)) / numel(data));
%err = sum(reperror2(data, D, Gamma)) / numel(data);
end


%% �ֿ����в��ƽ����
function err2 = reperror2(X, D, Gamma)

err2 = zeros(1, size(X, 2));
XXX = zeros(size(X, 1), size(X,2));

for i = 1 : size(X, 2)
    element_X = D * Gamma(:, i);
    for j = 1 : length(element_X)
        if element_X(j) <= 0
            element_X(j) = 0;
        else
            element_X(j) = round(element_X(j));
        end
    end
        
    XXX(:, i) = element_X;
    err2(i) = sum((X(:, i) - element_X) .^ 2);
end
xlswrite('dataset/general_ksvd/topics_data1/error/XXX.xlsx', XXX);
end
