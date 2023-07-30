rate = 100;
order = 4;
[b.mag, a.mag] = butter(order, 10/rate * 2, 'high');

mag = 