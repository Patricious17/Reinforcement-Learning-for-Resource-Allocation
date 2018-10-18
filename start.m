s = Simulation(5, "Linear");
p = Plotter('postPlot');
t = 1;
while(t<1200)
    s.step();
    t = t + 1;
end

Perr.data = s.irl.errorP;
Perr.t = (1 : length(s.irl.errorP));
p.postPlot(Perr);