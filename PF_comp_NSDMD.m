function [ PF, centers ] = PF_comp_NSDMD( x_limit, centers, fun, Tf,dT )
% Extended Dynamic Mode Decomposition and/or Naturally Structured DMD 
% main script for 1D nonlinear example
% Nx: number of basis functions chosen
xmax=x_limit(2);xmin=x_limit(1);
Dx=(xmax-xmin);
%% Generate time sequence of data
z0 = Dx*rand(1,100)-Dx/2; % Intial conditions in (-3 3)

N = size(z0,2); % number of initial conditions
data = [];
X = [];
Y = [];

for i = 1:N
    [t, z] = ode45(fun,[0:dT:Tf],z0(:,i));
    X = [X z(1:end-1,:)'];
    Y = [Y z(2:end,:)'];
    data = [data z'];
    figure(4)
    plot(t,z)
    hold on
end

% t = 0:dT:Tf;
% for i = 1:N
%     z(:,1) = z0(:,i);
%  	for tt = 1:length(t)-1
%         z(:,tt+1) = feval(fun,0,z(:,tt));
%     end
%     X = [X z(:,1:end-1)];
%     Y = [Y z(:,2:end)];
%     data = [data z];
%     figure(4)
%     plot(t,z)
%     hold on
% %     pause
% end
%% choice of dictionary
% Psi = @Usd_func;
% % Hermite Polynomials ---Problems defined on R^N
% Psi = @HermitePoly;

% Radial Basis Functions ---Problems defined on irregular domains
Psi = @RBF;

sigma = 0.05;
Lambda = (pi*sigma^2/2)^(size(data,1)/2)*exp(-squareform(pdist(centers').^2)./(2*sigma^2));

% Discontinuous Spectral Elements ---Large problems where a block-diagonal G is benecial/computationally important
% Psi = @DSE;

% % Plot the trajectory of time domain simulation and centers of dictionary functions
% figure(1)
% plot(data(1,:),data(2,:),'*')
% hold on
% plot(centers(1,:),centers(2,:),'+')
% 
% % subplot(1,2,1)
% % % scatter(centers(1,:),centers(2,:),1./sigma/100)
% % scatter(centers(1,:),centers(2,:),pi*(sigma).^2)
% % subplot(1,2,2)
% % plot(data(1,:),data(2,:),'*')

%% Compute the G and A matrix
G = 0;
A = 0;
M = size(X,2); % length of time-series
for i = 1:M
    PsiX = Psi(X(:,i),centers,sigma);
    PsiY = Psi(Y(:,i),centers,sigma);
    G = G + PsiX'*PsiX;
    A = A + PsiX'*PsiY;
end
G = G/M;
A = A/M;

% % EDMD
% Kdmd = pinv(G)*A;
% method = 'EDMD';

% NSDMD
m = size(A,2);
Zeros_m = zeros(1,m);
Ones_m = ones(m,1);
Vec = Lambda\Ones_m;


LambdaInv = inv(Lambda);
%% YALMIP
K = sdpvar(m,m,'full');
Objective =  norm(G*K-A,'fro'); % trace(Q); %
Constraints = [];
for i = 1:m
   Constraints = [Constraints, Zeros_m <= K(i,:)];
      Constraints = [Constraints, K(i,:)*Vec == Vec(i)];
            Constraints = [Constraints, Zeros_m <= K(i,:)*LambdaInv];
end

% opt = sdpsettings('solver','mosek-sdp','verbose',0);
opt = sdpsettings('solver','gurobi','verbose',0);
% Try this if u install Gurobi
sol = optimize(Constraints,Objective,opt)
Kdmd = value(K);

% At = A';
% b = At(:);
% A = kron(G,sparse(eye(m)));
% C = sparse(kron(Lambda,inv(Lambda)));
% M = kron(sparse(eye(m)),ones(1,m));
% M_new = M*C;
% % YALMIP
% x = sdpvar(m^2,1);
% Objective = norm(A*x-b);
% Constraints = [C*x >= 0; M_new*x == Ones_m; x >= 0];
% % opt = sdpsettings('solver','mosek-sdp','verbose',0);
% opt = sdpsettings('solver','gurobi','verbose',0);
% sol = optimize(Constraints,Objective,opt)
% Kdmd = reshape(value(x),m,m)';

% Kdmd = projGradient(G,A);

% Kdmd = projGradient2(G,A,Vec);

% Kdmd = projGradient4(G,A,Lambda);

% method = 'NSDMD';

% %% Plotting eigenfunctions 
% n = 4; % Compute eigenfunctions corresponding to first n dominant eigenvalues
% % Construct X-Y boxes
% Nx = 100;
% Ny = 100;
% x_limit = [-3 3]; % range of x
% y_limit = [-3 3]; % range of y
% xmax=x_limit(2); xmin=x_limit(1);
% ymax=y_limit(2); ymin=y_limit(1);
% dx=(xmax-xmin)/(Nx);
% dy=(ymax-ymin)/(Ny);
% xvec = xmin+dx/2:dx:xmax-dx/2;
% yvec = ymin+dy/2:dy:ymax-dy/2;
% [xx,yy] = meshgrid(xvec,yvec);
% x = reshape(xx,1,[]);
% y = reshape(yy,1,[]);
% XY =  [x;y];
% 
% [V, D] = eig(Kdmd); % D are eigenvalues of Koopman Operator or ln(D)/dT
PF = (Lambda*Kdmd/Lambda)';



end

