function [D,Gamma,err,gerr] = KSVD2(params,varargin)

%%
%KSVD K-SVD dictionary training.
%  [D,GAMMA] = KSVD(PARAMS) runs the K-SVD dictionary training algorithm on
%  the specified set of signals, returning the trained dictionary D and the
%  signal representation matrix GAMMA.
%
%  KSVD has two modes of operation: sparsity-based and error-based. For
%  sparsity-based minimization, the optimization problem is given by
%
%      min  |X-D*GAMMA|_F^2      s.t.  |Gamma_i|_0 <= T
%    D,Gamma
%
%  where X is the set of training signals, Gamma_i is the i-th column of
%  Gamma, and T is the target sparsity. For error-based minimization, the
%  optimization problem is given by
%
%      min  |Gamma|_0      s.t.  |X_i - D*Gamma_i|_2 <= EPSILON
%    D,Gamma
%
%  where X_i is the i-th training signal, and EPSILON is the target error.
%
%  [D,GAMMA,ERR] = KSVD(PARAMS) also returns the target function values
%  after each algorithm iteration. For sparsity-constrained minimization,
%  the returned values are given by
%
%    ERR(D,GAMMA) = RMSE(X,D*GAMMA) = sqrt( |X-D*GAMMA|_F^2 / numel(X) ) .
%
%  For error-constrained minimization, the returned values are given by
%
%    ERR(D,GAMMA) = mean{ |Gamma_i|_0 } = |Gamma|_0 / size(X,2) .
%
%  Error computation slightly increases function runtime.
%
%  [D,GAMMA,ERR,GERR] = KSVD(PARAMS) computes the target function values on
%  the specified set of test signals as well, usually for the purpose of
%  validation (testing the generalization of the dictionary). This requires
%  that the field 'testdata' be present in PARAMS (see below). The length
%  of ERR and GERR is identical.
%
%  [...] = KSVD(...,VERBOSE) where VERBOSE is a character string, specifies
%  messages to be printed during the training iterations. VERBOSE should
%  contain one or more of the characters 'i', 'r' and 't', each of which
%  corresponds to a certain piece of information:
%
%    i - iteration number
%    r - number of replaced atoms
%    t - target function value (and its value on the test data if provided)
%
%  Specifying either 'r', 't' or both, also implies 'i' automatically. For
%  example, KSVD(PARAMS,'tr') prints the iteration number, number of
%  replaced atoms, and target function value, at the end of each iteration.
%  The default value for VERBOSE is 't'. Specifying VERBOSE='' invokes
%  silent mode, and cancels all messages.
%
%  [...] = KSVD(...,MSGDELTA) specifies additional messages to be printed
%  within each iteration. MSGDELTA should be a positive number representing
%  the interval in seconds between messages. A zero or negative value
%  indicates no such messages (default). Note that specifying VERBOSE=''
%  causes KSVD to run in silent mode, ignoring the value of MSGDELTA.
%
%
%  Required fields in PARAMS:
%  --------------------------
%
%    'data' - Training data.
%      A matrix containing the training signals as its columns.
%
%    'Tdata' / 'Edata' - Sparse coding target.
%      Specifies the number of coefficients (Tdata) or the target error in
%      L2-norm (Edata) for coding each signal. If only one is present, that
%      value is used. If both are present, Tdata is used, unless the field
%      'codemode' is specified (below).
%
%    'initdict' / 'dictsize' - Initial dictionary / no. of atoms to train.
%      At least one of these two should be present in PARAMS.
%
%      'dictsize' specifies the number of dictionary atoms to train. If it
%      is specified without the parameter 'initdict', the dictionary is
%      initialized with dictsize randomly selected training signals.
%
%      'initdict' specifies the initial dictionary for the training. It
%      should be either a matrix of size NxL, where N=size(data,1), or an
%      index vector of length L, specifying the indices of the examples to
%      use as initial atoms. If 'dictsize' and 'initdict' are both present,
%      L must be >= dictsize, and in this case the dictionary is
%      initialized using the first dictsize columns from initdict. If only
%      'initdict' is specified, dictsize is set to L.
%
%
%  Optional fields in PARAMS:
%  --------------------------
%
%    'testdata' - Validation data.
%      If present, specifies data on which to compute generalization error.
%      Should be a matrix containing the validation signals as its columns.
%
%    'iternum' - Number of training iterations.
%      Specifies the number of K-SVD iterations to perform. If not
%      specified, the default is 10.
%
%    'memusage' - Memory usage.
%      This parameter controls memory usage of the function. 'memusage'
%      should be one of the strings 'high', 'normal' (default) or 'low'.
%      When set to 'high', the fastest implementation of OMP is used, which
%      involves precomputing both G=D'*D and DtX=D'*X. This increasese
%      speed but also requires a significant amount of memory. When set to
%      'normal', only the matrix G is precomputed, which requires much less
%      memory but slightly decreases performance. Finally, when set to
%      'low', neither matrix is precomputed. This should only be used when
%      the trained dictionary is highly redundant and memory resources are
%      very low, as this will dramatically increase runtime. See function
%      OMP for more details.
%
%    'codemode' - Sparse-coding target mode.
%      Specifies whether the 'Tdata' or 'Edata' fields should be used for
%      the sparse-coding stopping criterion. This is useful when both
%      fields are present in PARAMS. 'codemode' should be one of the
%      strings 'sparsity' or 'error'. If it is not present, and both fields
%      are specified, sparsity-based coding takes place.
%
%    'exact' - Exact K-SVD update.
%      Specifies whether the exact or approximate dictionary update
%      should be used. By default, the approximate computation is used,
%      which is significantly faster and requires less memory. Specifying a
%      nonzero value for 'exact' causes the exact computation to be used
%      instead, which slows down the method but provides slightly improved
%      results. The exact update uses SVD to solve the rank-1 minimization
%      problem, while the approximate upate performs alternate-optimization
%      to solve this problem.
%
%
%  Optional fields in PARAMS - advanced:
%  -------------------------------------
%
%    'maxatoms' - Maximal number of atoms in signal representation.
%      When error-based sparse coding is used, this parameter can be used
%      to specify a hard limit on the number of atoms in each signal
%      representation (see parameter 'maxatoms' in OMP2 for more details).
%
%    'muthresh' - Mutual incoherence threshold.
%      This parameter can be used to control the mutual incoherence of the
%      trained dictionary, and is typically between 0.9 and 1. At the end
%      of each iteration, the trained dictionary is "cleaned" by discarding
%      atoms with correlation > muthresh. The default value for muthresh is
%      0.99. Specifying a value of 1 or higher cancels this type of
%      cleaning completely. Note: the trained dictionary is not guaranteed
%      to have a mutual incoherence less than muthresh. However, a method
%      to track this is using the VERBOSE parameter to print the number of
%      replaced atoms each iteration; when this number drops near zero, it
%      is more likely that the mutual incoherence of the dictionary is
%      below muthresh.
%
%
%   Summary of all fields in PARAMS:
%   --------------------------------
%
%   Required:
%     'data'                   training data
%     'Tdata' / 'Edata'        sparse-coding target
%     'initdict' / 'dictsize'  initial dictionary / dictionary size
%
%   Optional (default values in parentheses):
%     'testdata'               validation data (none)
%     'iternum'                number of training iterations (10)
%     'memusage'               'low, 'normal' or 'high' ('normal')
%     'codemode'               'sparsity' or 'error' ('sparsity')
%     'exact'                  exact update instead of approximate (0)
%     'maxatoms'               max # of atoms in error sparse-coding (none)
%     'muthresh'               mutual incoherence threshold (0.99)
%
%
%  References:
%  [1] M. Aharon, M. Elad, and A.M. Bruckstein, "The K-SVD: An Algorithm
%      for Designing of Overcomplete Dictionaries for Sparse
%      Representation", the IEEE Trans. On Signal Processing, Vol. 54, no.
%      11, pp. 4311-4322, November 2006.
%  [2] M. Elad, R. Rubinstein, and M. Zibulevsky, "Efficient Implementation
%      of the K-SVD Algorithm using Batch Orthogonal Matching Pursuit",
%      Technical Report - CS, Technion, April 2008.
%
%  See also KSVDDENOISE, OMPDENOISE, OMP, OMP2.


%%
%  Ron Rubinstein
%  Computer Science Department
%  Technion, Haifa 32000 Israel
%  ronrubin@cs
%
%  August 2009


%% ȫ�ֱ�������

% ��������������ģʽ���ֻ���ϡ������ƺͻ��ڲв�����2��
global CODE_SPARSITY CODE_ERROR codemode

% �ڴ�ʹ��״̬����low��normal��high3��
global MEM_LOW MEM_NORMAL MEM_HIGH memusage

% omp������omp��������ȷsvd�����ʶ����
global ompfunc ompparams exactsvd  

% ���¶����������Ķ�Ӧ��ʶ
CODE_SPARSITY = 1;
CODE_ERROR = 2;

MEM_LOW = 1;
MEM_NORMAL = 2;
MEM_HIGH = 3;


%%
%%%%% ���½���������� %%%%%

%%
data = params.data;  % ԭʼ�ź�����
ompparams = {'checkdict', 'off'};

%% ��������������ģʽ %%
if (isfield(params, 'codemode'))
    switch lower(params.codemode)
        case 'sparsity'
            codemode = CODE_SPARSITY;
            thresh = params.Tdata;
        case 'error'
            codemode = CODE_ERROR;
            thresh = params.Edata;
        otherwise
            error('Invalid coding mode specified');
    end
elseif (isfield(params, 'Tdata'))
    codemode = CODE_SPARSITY;
    thresh = params.Tdata;
elseif (isfield(params, 'Edata'))
    codemode = CODE_ERROR;
    thresh = params.Edata;
    
else
    error('Data sparse-coding target not specified');
end

if (codemode == CODE_ERROR && isfield(params, 'maxatoms'))
    ompparams{end + 1} = 'maxatoms';  % Ԫ�������end+1ά��ֵһ����ǩ
    ompparams{end + 1} = params.maxatoms; % ���ڱ�ʾ�����źŵ��ֵ�ԭ�ӵ�������
end


%% �ڴ�ʹ�� %%
% ��low��normal��high3��״̬
if (isfield(params, 'memusage'))
    switch lower(params.memusage)
        case 'low'
            memusage = MEM_LOW;
        case 'normal'
            memusage = MEM_NORMAL;
        case 'high'
            memusage = MEM_HIGH;
        otherwise
            error('Invalid memory usage mode');
    end
else
    % Ĭ��Ϊnormal
    memusage = MEM_NORMAL;
end


%% �������� %%
if (isfield(params, 'iternum'))
    iternum = params.iternum;
else
    % Ĭ�ϵ�������Ϊ10
    iternum = 10;
end


%% OMP���� %%
if (codemode == CODE_SPARSITY)
    % ����ǻ���ϡ������ƣ���ô��omp
    ompfunc = @omp;
else
    % ����ǻ��ڲв����ƣ���ô��omp2
    ompfunc = @omp2;
end


%% ״̬��Ϣ��ʶ %%
printiter = 0;
printreplaced = 0;
printerr = 0;
printgerr = 0;

verbose = 't';
msgdelta = -1;  % �����ʾ�ĵ��ӳ�ͣ��ʱ��

for i = 1:length(varargin)
    if (ischar(varargin{i}))
        verbose = varargin{i};
    elseif (isnumeric(varargin{i}))
        msgdelta = varargin{i};
    else
        error('Invalid call syntax');
    end
end

for i = 1:length(verbose)
    switch lower(verbose(i))
        case 'i'
            printiter = 1;
        case 'r'
            printiter = 1;
            printreplaced = 1;
        case 't'
            printiter = 1;
            printerr = 1;
            if (isfield(params,'testdata'))
                printgerr = 1;
            end
    end
end

if (msgdelta<=0 || isempty(verbose))
    msgdelta = -1;
end

ompparams{end + 1} = 'messages';
ompparams{end + 1} = msgdelta;

% ������������ڵ���3��������Ҫ����в�仯������ʱ����Ҫʹ����в��ʶΪ1
comperr = (nargout >= 3 || printerr);  % ����в��ʶ


%% ��֤��ʶ %%
testgen = 0;  % Ĭ����������֤
if (isfield(params, 'testdata'))
    testdata = params.testdata;
    if (nargout >= 4 || printgerr)
        % �������gerr�����������֤
        testgen = 1;
    end
end


%% �в�������һ�� %%
XtX = []; 
XtXg = [];
if (codemode == CODE_ERROR && memusage == MEM_HIGH)
    % ���������ֹ׼���ǻ��ڲв����Ƶ�ģʽ�Լ��ڴ�ʹ��״̬Ϊhigh
    % �ҳ�ԭʼ�ź����ݰ��зֿ�����ƽ��������������ά��Ϊ�ֿ����Ŀ
    XtX = colnorms_squared(data);
    if (testgen)
        % ����������֤�������������֤�����ݵ�ƽ��������
        XtXg = colnorms_squared(testdata);
    end
end


%% �����ϵ����ֵ�趨 %%
if (isfield(params, 'muthresh'))
    muthresh = params.muthresh;
else
    muthresh = 0.99;
end
if (muthresh < 0)
    error('invalid muthresh value, must be non-negative');
end


%% ��ȷsvd���� %
exactsvd = 0;  % ��ȷsvd�����ʶ
if (isfield(params, 'exact') && params.exact ~= 0)
    exactsvd = 1;
end


%% ��ѵ���ֵ�ԭ������ȷ�� %%
if (isfield(params, 'initdict'))
    % any�ж�Ԫ���Ƿ�Ϊ0�����㷵��1��all����������Ϊ��0�򷵻��߼�ֵ1.���򷵻��߼�ֵ0
    % ��ʵ���������жϾ�����һά���Ƕ�ά
    if (any(size(params.initdict) == 1) && all(iswhole(params.initdict(:))))
        % ���������һά��������������������ÿһ��ֵ��ʾ��Ӧ��ԭʼ�ź����ݵ�λ��
        % ����ĳ����ԭʼ�ź�������Ϊ��ѵ���ֵ��ԭ������
        % ��ô��ѵ���ֵ��ԭ�����͸����������ĳ���һ��
        dictsize = length(params.initdict);  
    else
        % ���������ʹ�ø����ĳ�ʼ�ֵ��������Ϊѵ���ֵ��ԭ����
        dictsize = size(params.initdict, 2);  
    end
end

% ����������ֱ�Ӹ�����ѵ���ֵ��ԭ��������ô��ֱ��ʹ��
% ���������������������Ȩ
if (isfield(params, 'dictsize')) 
    dictsize = params.dictsize;
end

% ���ԭʼ�ź����ݸ���С���ֵ�ԭ�����������׳�����
if (size(data, 2) < dictsize)
    error('Number of training signals is smaller than number of atoms to train');
end


%% ��ʼ����ѵ���ֵ� %%
if (isfield(params, 'initdict'))
    if (any(size(params.initdict) == 1) && all(iswhole(params.initdict(:))))
        % ʹ��ĳ����ԭʼ�ź�������Ϊ��ʼ�ֵ�
        D = data(:, params.initdict(1:dictsize));
    else
        if (size(params.initdict,1) ~= size(data, 1) || size(params.initdict, 2) < dictsize)
            % ��������ĳ�ʼ�ֵ������ԭʼ�ź����ݵ�ά�Ȳ�һ��
            % ���߸����ĳ�ʹ���������С�ڴ�ѵ���ֵ�ԭ�Ӹ��������׳�����
            error('Invalid initial dictionary');
        end
        % �����趨��ԭ������ȡ�����ĳ�ʼ���ֵ����
        % ��Ϊ����������ĳ�ʼ�ֵ��ԭ����Ŀ���ܱ��趨���ֵ��ԭ����ĿҪ��
        D = params.initdict(:, 1:dictsize);  
    end
else
    % �ҳ�ԭʼ�ź������зֿ���ƽ���ʹ���0�Ŀ�
    % colnorms_squared(data)�õ�����һ��1x����������
    data_ids = find(colnorms_squared(data) > 1e-6);
    % ����1��length(data_ids)֮���length(data_ids)���������
    perm = randperm(length(data_ids));
    % ���ѡȡԭʼ�ź����ݵ�һЩ�г�ʼ���ֵ�
    D = data(:, data_ids(perm(1 : dictsize)));
end


%% ��һ���ֵ� %%
D = normcols(D);  % L2������һ��
err = zeros(1, iternum);  % �в�����
gerr = zeros(1, iternum);  % ������������������������ѵ������ͬ�ֲ��Ķ������������ϵ�ƽ����ʧ

if (codemode == CODE_SPARSITY)
    % ����ϡ������Ƶ����Σ�Ĭ���Ǹ�ѡ��
    errstr = 'RMSE';
else
    % ���ڲв����Ƶ�����
    errstr = 'mean atomnum';
end


%%  ����������  %%
for iter = 1 : iternum
    printf('KSVD��%d�ε���', iter);
    G = [];
    if (memusage >= MEM_NORMAL)
        G = D' * D;  % �ڴ�ʹ��״̬Ϊnormal��highʱ��G��ҪԤ����
    end
    
    %%%%%  ϡ���ʾ  %%%%%
    % �������
    % data��ԭʼ�źž��� D���ֵ䣻
    % XtX���в������� G��D'*D�� thresh����ֵ
    Gamma = sparsecode(data, D, XtX, G, thresh);  % GammaΪϡ��ϵ������
    
    %%%%%  �ֵ����  %%%%%
    replaced_atoms = zeros(1, dictsize);  % ÿ�θ��µ�ԭ�ӵ�����������ʼ��Ϊ0����
    unused_sigs = 1 : size(data, 2);  % δ��ʾ��ԭʼ�ź���������
    
    % ȷ��ÿһ���ź�ֻ������һ��
    p = randperm(dictsize);  % ��1��dictsize֮���������dictsize���������
    tid = timerinit('updating atoms', dictsize);  % ��ʼ����ʱ��
    for j = 1 : dictsize
        % ����ԭ��
        % �ɸĶ��˴���ʹ�ֵ�ԭ��������
        [D(:, p(j)), gamma_j, data_indices, unused_sigs, replaced_atoms] = optimize_atom(data, D, p(j), Gamma, unused_sigs, replaced_atoms);
        % ����ϡ��ϵ��
        Gamma(p(j), data_indices) = gamma_j;
        
        if (msgdelta > 0)
            % ����ʣ��ʱ�䣬ֱ����ʾ
            % ���������tid����ʱ����j��Ŀǰ����������msgdelta�������ʾ�ĵ��ӳ�ͣ��ʱ��
            timereta(tid, j, msgdelta); 
        end
    end
    if (msgdelta > 0)
        printf('updating atoms: iteration %d/%d', dictsize, dictsize);
    end
    
    %%%%%  ����в�  %%%%%
    if (comperr)
        err(iter) = compute_err(D, Gamma, data);
    end
    if (testgen)
        if (memusage >= MEM_NORMAL)
            G = D' * D;
        end
        GammaG = sparsecode(testdata, D, XtXg, G, thresh);
        % ����������֤���ݼ���
        gerr(iter) = compute_err(D, GammaG, testdata);
    end
    
    %%%%%  �����ֵ��е�ԭ��  %%%%%    
    [D, cleared_atoms] = cleardict(D, Gamma, data, muthresh, unused_sigs, replaced_atoms);
    
    %%%%%  ��ӡ��Ϣ  %%%%%
    info = sprintf('Iteration %d / %d complete', iter, iternum);
    if (printerr)
        info = sprintf('%s, %s = %.4g', info, errstr, err(iter));
    end
    if (printgerr)
        info = sprintf('%s, test %s = %.4g', info, errstr, gerr(iter));
    end
    if (printreplaced)
        info = sprintf('%s, replaced %d atoms', info, sum(replaced_atoms) + cleared_atoms);
    end
    
    if (printiter)
        disp(info);
        if (msgdelta > 0), disp(' '); end
    end
    
end  % ���������˽���

end  % �����������˽��������һ�����Ӧ



%%
%%%%% ���¾�Ϊ���ĺ��� %%%%%

%% ����ԭ�� %%
% ���������
%     X��ԭʼ�����źž���
%     D���ֵ�
%     j���������ֵ����ʾ�ֵ��е�ĳ�У�����ʾĳ��ԭ��
%     Gamma��ϡ��ϵ������
%     unused_sigs��δ����ʾ��ԭʼ�ź�
%     replaced_atoms����ȡ����ԭ��
% ���������
%     atom�����º��ԭ��
%     gamma_j��ϡ��ϵ�������е�j���еķ�0Ԫ�ع��ɵ�����
%     data_indices��ϡ��ϵ�������е�j���еķ�0Ԫ�ص�����λ�ù��ɵ�����
%     unused_sigs��δ����ʾ��ԭʼ�ź�
%     replaced_atoms����ȡ����ԭ��
%
function [atom, gamma_j, data_indices, unused_sigs, replaced_atoms] = optimize_atom(X, D, j, Gamma, unused_sigs, replaced_atoms)

global exactsvd  % ��ȷSVD

% data samples which use the atom, and the corresponding nonzero
% coefficients in Gamma
% ����ϡ��ϵ�������е�j���еķ�0Ԫ�ؼ�������λ��
[gamma_j, data_indices] = sprow(Gamma, j);

% ��ϡ��ϵ�������е�j���е�Ԫ��ȫΪ0
if (length(data_indices) < 1)
    maxsignals = 5000;
    perm = randperm(length(unused_sigs));  % length(unused_sigs)���ǻ�δ����ʾ�źŸ�������ʼʱΪX��������ÿѭ��һ�μ�1
    perm = perm(1 : min(maxsignals, end));  % ��perm��ά����5000����ֻȡ��ǰ5000��
    
    % ����в�ƽ��
    E = sum((X(:, unused_sigs(perm)) - D * Gamma(:, unused_sigs(perm))) .^ 2);
    [d, i] = max(E);  % dΪE��ÿһ�е����ֵ���ɵ�������iΪÿһ�����ֵ���кŹ��ɵ�����
    
    % ���ź�������ȡ��Ӧ������Ϊԭ�ӣ�����һ��
    atom = X(:, unused_sigs(perm(i)));
    
    if (j > 1)
        % ���ѵõ��������ֵ�ԭ������������
        [DictionaryUpdate, RR] = qr([D(:, 1:(j - 1)), atom], 0);
        atom = DictionaryUpdate(:, j);  % ���º��ԭ��ȡ������������һ��
    else
        atom = atom ./ norm(atom);
    end
    
    gamma_j = zeros(size(gamma_j));  % ���±�Ϊ0����
    unused_sigs = unused_sigs([1 : perm(i) - 1, perm(i) + 1 : end]);  % ȥ���Ѿ�����ʾ���ź�
    replaced_atoms(j) = 1;  % �ڱ��滻ԭ����������Ӧλ�ã�����j����1
    return;
end

smallGamma = Gamma(:, data_indices);
Dj = D(:, j);

if (exactsvd)
    % ���辫ȷSVD����
    % �˴�svds������ֽ�Ϊmx1,1x1,1xn
    % �Ķ��˴���ʵ�������ֵ�
    EJ = X(:, data_indices) - D * smallGamma + Dj * gamma_j;  % ȥ����ǰԭ�ӳɷ�����ɵ�������
    [atom, s, gamma_j] = svds(EJ, 1);
    if (j > 1)
        % ���ѵõ��������ֵ�ԭ������������
        [DictionaryUpdate, RR] = qr([D(:, 1:(j - 1)), atom], 0);
        atom = DictionaryUpdate(:, j);  % ���º��ԭ��ȡ������������һ��
        gamma_j = atom \ EJ;
    else
        gamma_j = s * gamma_j;  % �����ֵ�ԭ��֮��ҲҪ������Ӧ��ϡ��ϵ��
    end 
else
    % �����辫ȷSVD����
    % ��ԭʼ�ź��е�ĳ�����е���������ټ�ȥ[���õ��������ֵ�ԭ�����õ�����]���ּ���[����֮ǰ�ĸ��е��ֵ�ԭ��]��Ϊ���µ�ԭ��
    atom = collincomb(X, data_indices, gamma_j') - D * (smallGamma * gamma_j') + Dj * (gamma_j * gamma_j');
    
    if (j > 1)
        % ���ѵõ��������ֵ�ԭ������������
        [DictionaryUpdate, RR] = qr([D(:, 1:(j - 1)), atom], 0);  % ���������̰�����һ��
        atom = DictionaryUpdate(:, j);  % ���º��ԭ��ȡ������������һ��
    else
        atom = atom ./ norm(atom);  % ��һ��
    end

    % ����ϡ��ϵ��
    gamma_j = rowlincomb(atom, X, 1 : size(X, 1), data_indices) - (atom' * D) * smallGamma + (atom' * Dj) * gamma_j;  
end

end


%% ϡ���ʾ %% 
% �������
%     data��ԭʼ�źž���
%     D���ֵ�
%     XtX���в����� 
%     G��D'*D 
%     thresh����ֵ
function Gamma = sparsecode(data, D, XtX, G, thresh)

global CODE_SPARSITY codemode  % ����������ģʽ������ϡ��ȵ�������ģʽ
global MEM_HIGH memusage  % high������ڴ�ʹ��ģʽ
global ompfunc ompparams  % omp��������ز���

if (memusage < MEM_HIGH)
    % memusage����high
    % ompparams{:}��ompparamsԪ������ת���ɵ�������
    % �˴����õ���omp2
    Gamma = ompfunc(D, data, G, thresh, ompparams{:});
    
else  
    % memusage��high
    if (codemode == CODE_SPARSITY)
        % ����ϡ��ȵ�������ģʽ�����õ���omp
        Gamma = ompfunc(D' * data, G, thresh, ompparams{:});      
    else
        % ���ڲв��������ģʽ����ʱҪ�����в�����XtX�����õ���omp2
        Gamma = ompfunc(D' * data, XtX, G, thresh, ompparams{:});
    end
end

end


%% ����в� %%
function err = compute_err(D, Gamma, data)

global CODE_SPARSITY codemode

if (codemode == CODE_SPARSITY)
    % ����ϡ������ƵĲв����
    err = sqrt(sum(reperror2(data, D, Gamma)) / numel(data));
else
    % ����������ƵĲв����
    err = nnz(Gamma) / size(data, 2);
end

end


%% �����ֵ��е�ԭ�� %%
% ���������
%     D���ֵ�
%     Gamma��ϡ��ϵ������
%     X��ԭʼ�����źž���
%     muthresh���������ֵ
%     unused_sigs��δ����ʾ��ԭʼ�ź�
%     replaced_atoms����ȡ����ԭ��
function [D, cleared_atoms] = cleardict(D, Gamma, X, muthresh, unused_sigs, replaced_atoms)

use_thresh = 4;  % at least this number of samples must use the atom to be kept

dictsize = size(D, 2);

% �ֿ����в�
err = zeros(1, size(X, 2));
blocks = [1 : 3000 : size(X, 2) size(X, 2) + 1];
for i = 1 : length(blocks) - 1
    err(blocks(i) : blocks(i + 1) - 1) = sum((X(:, blocks(i) : blocks(i + 1) - 1) - D * Gamma(:, blocks(i) : blocks(i + 1) - 1)) .^ 2);
end

cleared_atoms = 0;
usecount = sum(abs(Gamma) > 1e-7, 2);

for j = 1:dictsize
    % compute G(:,j)
    Gj = D' * D(:,j);
    Gj(j) = 0;
    
    % replace atom
    if ( (max(Gj .^ 2) > muthresh^2 || usecount(j) < use_thresh) && ~replaced_atoms(j) )
        [y, i] = max(err(unused_sigs));
        D(:, j) = X(:, unused_sigs(i)) / norm(X(:, unused_sigs(i)));
        unused_sigs = unused_sigs([1 : i - 1, i + 1 : end]);
        cleared_atoms = cleared_atoms + 1;
    end
end

end


%% �ֿ����в��ƽ����
function err2 = reperror2(X,D,Gamma)

err2 = zeros(1, size(X, 2));
blocksize = 2000;
for i = 1 : blocksize : size(X, 2)
    blockids = i : min(i + blocksize - 1, size(X, 2));
    err2(blockids) = sum((X(:, blockids) - D * Gamma(:, blockids)) .^ 2);
end

end


%% �����й�һ�� %%
% �ֿ�����Լ�ڴ�
function Y = colnorms_squared(X)
Y = zeros(1, size(X, 2));
blocksize = 2000;  % ��Ĵ�СΪ2000����������������2000����Ҫ�ֿ����
for i = 1 : blocksize : size(X, 2)
    % ��ı������
    blockids = i : min(i + blocksize - 1, size(X, 2));
    Y(blockids) = sum(X(:, blockids) .^ 2);  % ��ÿһ��ĵ�ǰ�н��й�һ������
end

end
