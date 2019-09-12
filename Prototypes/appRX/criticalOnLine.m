%return all critical points of the simplified Qi landscape over a line which angular coefficient is phi
%zero is the maximum number to be considered as zero.
function [dX,dY,Z] = criticalOnLine(alpha,beta,gamma,a,phi,zero)
   A = -(beta-2*alpha+gamma*phi)*(phi^2+1);
   B = -2*(alpha-beta-gamma*phi)*(phi^2+1);
   C = -(alpha-beta-gamma*phi)*(-2*phi^2)+(beta-2*alpha+gamma*phi)*phi^2;

   if(abs(A/mean([A,B,C]))<zero)
       dX = -C/B;
   else
       delta = B^2-4*A*C;
       if delta==1
           dX = -B/(2*A);
       else
           if delta<0
               dX = [];
           else
               dX = (-B+[1,-1]*sqrt(delta))/(2*A);
           end
       end
   end

   %dx = linspace(-2,4,100000);
   dY = phi*(dX-1);
   Z = ((beta-2*alpha+gamma*phi)*dX+alpha-beta-gamma*phi)./((phi^2+1)*dX.^2-2*phi^2*dX+phi^2);

   %validating the found points
   dx0 = linspace(-5,9,1000000);
   dy0 = phi*(dx0-1);
   Z0 = ((beta-2*alpha)*dx0+gamma*dy0+alpha-beta)./(dx0.^2+dy0.^2);
   [M,ind] = max(Z0);
   if(max(Z)+zero<M)
       global SubOptimalsLine;                                                                     
       if isempty(SubOptimalsLine), SubOptimalsLine=1;, else, SubOptimalsLine=SubOptimalsLine+1;,end
   else
       global OptimalsLine;                                                                     
       if isempty(OptimalsLine), OptimalsLine=1;, else, OptimalsLine=OptimalsLine+1;,end
   end

end
