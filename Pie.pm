#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::Pie                 #
#                             #
#  written by karlon west     #
#  karlon@netcom.com          #
#  theft is treason, citizen  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Chart::Pie;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::Pie::ISA = qw(Chart::Base);
$Chart::Pie::VERSION = 0.90;

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#



#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

# Override the ticks methods for the pie charts
# as they do not always make sense.
sub _draw_x_ticks {
  my $self = shift;

  # draw the x ticks, if we're supposed to
  $self->SUPER::_draw_x_ticks unless $self->{'x_ticks'} =~ /^none$/i;

  # then return
  return;
}

sub _draw_y_ticks {
  my $self = shift;

  # draw the y ticks, if we're supposed to
  $self->SUPER::_draw_y_ticks unless $self->{'y_ticks'} =~ /^none$/i;

  # then return
  return;
}

sub _find_y_scale {
  my $self = shift;

  # find y scale, if we're supposed to
  $self->SUPER::_find_y_scale unless $self->{'y_ticks'} =~ /^none$/i;

  # then return
  return;
}

## finally get around to plotting the data
sub _draw_data {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $misccolor = $self->{'color_table'}{'misc'};
  my $background = $self->{'color_table'}{'background'};
  my ($width, $height, $centerX, $centerY, $diameter);
  my ($sum_total, $dataset_sum);
  my ($start_degrees, $end_degrees, $label_degrees);
  my ($pi, $font, $fontW, $fontH, $labelX, $labelY, $label_offset);
  my ($last_labelX, $last_labelY, $label);
  my ($i, $j, $color);

  # set up initial constant values
  $pi = 3.14159265;
  $start_degrees=0;
  $end_degrees=0;
  $font = $self->{'legend_font'};
  $label_offset = .6;
  $fontW = $self->{'legend_font'}->width;
  $fontH = $self->{'legend_font'}->height;
  $last_labelX = 0;
  $last_labelY = 0;

  # init the imagemap data field if they wanted it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # find width and height
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};

  # find center point, from which the pie will be drawn around
  $centerX = int($width/2)  + $self->{'curr_x_min'};
  $centerY = int($height/2) + $self->{'curr_y_min'};

  # always draw a circle, which means the diameter will be the smaller
  # of the width and height.
  $diameter  = ($centerX < $centerY ? $centerX : $centerY);

  # okay, add up all the numbers of all the datasets, to get the
  # sum total. This will be used to determine the percentage 
  # of each dataset. Obviously, negative numbers might be bad :)
  $sum_total=0;
  for $i (1..$self->{'num_datasets'}) {
     for $j (0..$self->{'num_datapoints'}) {
        if(defined $data->[$i][$j])
        {
           $sum_total += $data->[$i][$j];
        }
     }
  }

  # draw the bars
  for $i (1..$self->{'num_datasets'}) {

    # get the color for this dataset
    $color = $self->{'color_table'}{'dataset'.($i-1)};

    # Add up the sum for this dataset
    $dataset_sum=0;
    for $j (0..$self->{'num_datapoints'}) {
      # don't try to draw anything if there's no data
      if (defined ($data->[$i][$j])) {
         $dataset_sum += $data->[$i][$j];
      }
    }

    $label = $self->{'legend_labels'}[$i-1];
    if(defined $self->{'label_values'})
    {
       if($self->{'label_values'} =~ /^percent$/i)
       {
          $label = sprintf("%s %%%4.2f",$label,$dataset_sum / $sum_total * 100);
       }
       elsif($self->{'label_values'} =~ /^value$/i)
       {
          $label = sprintf("%s %d",$label,$dataset_sum);
       }
       elsif($self->{'label_values'} =~ /^both$/i)
       {
          $label = sprintf("%s %%%4.2f %d",$label,
                                          $dataset_sum / $sum_total * 100,
                                          $dataset_sum);
       }
    }    

    # The first value starts at 0 degrees, each additional dataset
    # stops where the previous left off, and since I've already 
    # calculated the sum_total for the whole graph, I know that
    # the final pie slice will end at 360 degrees.

    # So, get the degree offset for this dataset
    $end_degrees = $start_degrees + ($dataset_sum / $sum_total * 360);

    # stick the label in the middle of the slice
    $label_degrees = ($start_degrees + $end_degrees) / 2;

    # The following drawings are in a very specific ordering, and are not
    # intuitive as to why they are being done this way, but it is basically
    # because the GD module doesn't provide a filledArc() method. So, I
    # developed my own, below.
 
    # First, draw an arc, in black, from the starting offset, all the 
    # way to 360 degrees.
    $self->{'gd_obj'}->arc($centerX,$centerY,
                    $diameter, $diameter,
                    $start_degrees, 360,
                    $misccolor);

    # This is tricky, but draw a short line in the desired color, along the
    # path that will be the end of this pie slice of data. But, make sure not
    # to extend this line to intersect with the boundary of the arc. This
    # is crucial.
    $self->{'gd_obj'}->line($centerX, $centerY,
                    $centerX + .4*$diameter*cos($end_degrees*$pi/180),
                    $centerY + .4*$diameter*sin($end_degrees*$pi/180),
                    $color);

    # Draw the radius of the beginning side of the pie slice, in black
    $self->{'gd_obj'}->line($centerX,$centerY,
                    $centerX + .5*$diameter*cos($start_degrees*$pi/180),
                    $centerY + .5*$diameter*sin($start_degrees*$pi/180),
                    $misccolor);

    # Now, execute fillToBorder, starting from a point on the end line, in the
    # desired pie slice color, and fill until a black pixel if encountered.
    # What this means, is that a series of pie slices is drawn, each starting
    # at the correct location, but each ending at 360 degrees. 
    $self->{'gd_obj'}->fillToBorder(
                    $centerX + .4*$diameter*cos($end_degrees*$pi/180),
                    $centerY + .4*$diameter*sin($end_degrees*$pi/180),
                    $misccolor,$color);

    # Figure out where to place the label
    $labelX = $centerX+$label_offset*$diameter*cos($label_degrees*$pi/180);
    $labelY = $centerY+$label_offset*$diameter*sin($label_degrees*$pi/180);

    # If label is to the left of the pie chart, make sure the label doesn't
    # bleed into the chart. So, back it up the length of the label
    if($labelX < $centerX)
    {
       $labelX -= (length($label) * $fontW);
    }

    # Same thing if the label is above the chart. Don't go too low.
    if($labelY < $centerY)
    {
       $labelY -= $fontH;
    }

    # Okay, if a bunch of very small datasets are close together, they can
    # overwrite each other. The following if statement is to help keep
    # labels of neighbor datasets from beong overlapped. It ain't perfect,
    # but it des a pretty good job.
    if($label_degrees <= 90 || $label_degrees >= 270)
    {
       if(($labelY - $last_labelY) < $fontH                                      && 
          sqrt(($labelY-$last_labelY)**2 + ($labelX-$last_labelX)**2) < $fontH*2 &&
           $last_labelY > 0)
       {
          $labelY = $last_labelY + $fontH;
       }
    }
    else
    {
       if(($last_labelY - $labelY) < $fontH                                      &&
          sqrt(($labelY-$last_labelY)**2 + ($labelX-$last_labelX)**2) < $fontH*2 &&
          $last_labelY > 0)
       {
          $labelY = $last_labelY - $fontH;
       }
    }

    # Now, draw the label for this pie slice
    $self->{'gd_obj'}->string($font, $labelX, $labelY, $label, $misccolor);

    # reset starting point for next dataset and continue.
    $start_degrees = $end_degrees;
    $last_labelX = $labelX;
    $last_labelY = $labelY;
  }

  # and finaly box it off 
  $self->{'gd_obj'}->rectangle ($self->{'curr_x_min'},
                                $self->{'curr_y_min'},
                                $self->{'curr_x_max'},
                                $self->{'curr_y_max'},
                                $misccolor);
  return;

}

## be a good module and return 1
1;
