use Chart::Pie;

print "1..1\n";

$g = Chart::Pie->new(640,480);
$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (3, 4, 9);
$g->add_dataset (8, 6, 1);
$g->add_dataset (5, 7, 2);

$g->set ('title' => 'Pie Chart',
         'x_ticks' => 'none',
         'y_ticks' => 'none');

$g->gif ("samples/pie.gif");

print "ok 1\n";

exit (0);
