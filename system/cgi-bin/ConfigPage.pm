package ConfigPage;

use Conf;
use Category;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'browser'} =	undef;
	$self->{'conf'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}


sub output{
	my $proto = shift;
	my $fd = shift;
	
######### load new object
	my $self = $proto->new();

######### load Conf
	$self->{'conf'} = Conf->load();

######### authenticate browser
	if( $self->{'conf'}->browser($fd->field('browser')) ){
		$self->{'browser'} = $fd->field('browser');
	} else {
		$self->{'browser'} = $self->{'conf'}->defaultBrowser();
	}

warn "browser: " . $self->{'browser'};
warn "browsers: " . join( ' & ', $self->{'conf'}->browsers() );

######### merge config template
warn "template: " . $self->{'conf'}->template( $self->{'browser'}, "configure_site" );

	my $template = join( "\n", $self->{'conf'}->template($self->{'browser'},"configure_site")->merge($fd) );

######### get config page
	my $config = $self->config();

######### print content-type
	print "Content-type: text/html\015\012\015\012";
	
######### replace '<config />' with password form
	$template =~ s/<config\s*\/>/$config/gis;
	
######### print template
	print $template;
}

sub config{
	my $self = shift;
	
	my $config = "";
	
######### categories
	my @categories = $self->{'conf'}->categories();
	$config .= <<END;
<ul><font size="+2">categories</font>
<a href="form.cgi?browser=$self->{'browser'}&category=categories&form=new">new</a>
END
#warn "conf: " . $self->{'conf'};
	foreach my $category ( @categories ){
		my $c = $self->{'conf'}->category($category);
		my $cName = $c->field('name');
		my $cRecordNumber = $c->field('record_number');
		
		# dtd for fields
		my $dtd = Category->loadDtd( $cName );
		my( $parent_name ) = $dtd->parents();

		$config .= <<END;
<p><ul><font size="+1">$cName</font>
<a href="form.cgi?browser=$self->{'browser'}&category=categories&form=edit&number=$cRecordNumber">edit</a> .
<a href="form.cgi?browser=$self->{'browser'}&data=dtd&category=$cName&element=$parent_name&form=new">new field</a>
END
		# fields	
		foreach my $child_name ( $dtd->element( $parent_name )->children() ){
			if( $child_name ne "last_edited" && $child_name ne "subcategory" ){
				$self->configField( $child_name, $dtd, \$config, $cName );
			}
		}

		$config .= <<END;
</ul></p>
END
	}
	$config .= "</ul>";
	
######### browsers
	$config .= <<END;
<ul><font size="+2">browsers</font>
<a href="form.cgi?browser=$self->{'browser'}&category=browsers&form=new">new</a>
END
	foreach my $browser ( $self->{'conf'}->browsers() ){
		my $b = $self->{'conf'}->browser($browser);
		my $bName = $b->field('name');
		my $bRecordNumber = $b->field('record_number');
		$config .= <<END;
<p><ul><font size="+1">$bName</font>
<a href="form.cgi?browser=$self->{'browser'}&category=browsers&form=edit&number=$bRecordNumber">edit</a>
<br />&nbsp;&nbsp;templates: <a href="form.cgi?browser=$self->{'browser'}&category=${bName}_templates&form=new">new</a>
END
		foreach my $page ( $self->{'conf'}->pages($bName) ){
			my $t = $self->{'conf'}->templateRecord( $bName, $page );		
			my $tName = $t->field('type');
			my $tRecordNumber = $t->field('record_number');
			$config .= <<END;
<ul><li>$tName
<a href="form.cgi?browser=$self->{'browser'}&category=${bName}_templates&form=edit&number=$tRecordNumber">edit</a>
</li></ul>
END
		}
		foreach my $category ( @categories ){
			foreach my $page ( "index", "record", "reference" ){
#warn "browser: $bName, page: $page, category: $category";
				my $t = $self->{'conf'}->templateRecord( $bName, $page, $category );		
#warn "t: $t";
				if( $t =~ /Record/ ){
					my $tRecordNumber = $t->field('record_number');
					$config .= <<END;
<ul><li>$category $page
<a href="form.cgi?browser=$self->{'browser'}&category=${bName}_templates&form=edit&number=$tRecordNumber">edit</a>
</li></ul>
END
				}
			}
		}
		$config .= "</ul></p>";
	}
	$config .= "</ul>";
	
######### return config
	return $config;
}

sub configField{
	my $self = shift;
	my $field_name = shift;
	my $dtd = shift;
	my $page_ref = shift;
	my $category_name = shift;
	
	$$page_ref .= <<END;
<ul><li>$field_name <a href="form.cgi?browser=$self->{'browser'}&data=dtd&category=$category_name&element=$field_name&form=edit">edit</a> . 
<a href="form.cgi?browser=$self->{'browser'}&data=dtd&category=$category_name&element=$field_name&form=new">new child field</a></li>
END
	foreach my $child_name ( $dtd->element( $field_name )->children() ){
		$self->configField( $child_name, $dtd, $page_ref, $category_name );
	}
	$$page_ref .= "</ul>";
}
1;
