#!/usr/bin/env perl
use v5.26;
use Test::Most;
use PPI;
use Data::Dumper;
use experimental qw/ signatures /;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    "$0 %o <file(s)>",
    [],
    ['Check test modules for Mojo::Base statements (and optionally add them automatically)'],
    [],
    ['write',    'write changed file(s)'],
    ['help|h|?', "print usage and exit", {shortcircuit => 1}],
);

print($usage->text), exit if $opt->help;

my @files = @ARGV;

for my $file (@files) {
    my ($doc, $base_statements) = analyze($file);
    next unless $doc;
    my $changed = fix($file, $doc, $base_statements);
    if ($changed) {
        if ($opt->write) {
            diag "Writing $file";
            $doc->save($file);
        }
        else {
            diag "CHANGED:\n$changed\n";
        }
    }
}

sub fix ($file, $doc, $base_statements) {
    if (not $base_statements->{base} and not $base_statements->{mb}) {
        diag "No base statement at all, must inherit from basetest";
        return;
    }
    if (my $use_base = $base_statements->{base}) {
        my @classes;
        my $base = $use_base->{base};
        push @classes, @$base;
        my $stmt = $use_base->{object};

        if (my $use_mb = $base_statements->{mb}) {
            # Both 'use base' and 'use Mojo::Base'
            if (my $base_mb = $use_mb->{base}) {
                push @classes, @$base_mb;
                $use_mb->{object}->remove;
            }
            else {
                $use_mb->{object}->remove;
            }
        }

        my $new_code;
        if (@classes > 1) {
            $new_code = "use Mojo::Base qw(@classes), -signatures;\n\n";
        }
        else {
            $new_code = "use Mojo::Base '$classes[0]', -signatures;\n\n";
        }
        my $temp_doc = PPI::Document->new(\$new_code);
        my $new_statement = $temp_doc->child(0)->clone;

        $stmt->insert_before($new_statement);
        $stmt->remove;
        return $doc;
    }
    if (my $use_mb = $base_statements->{mb}) {
        my $base = $use_mb->{base};
        my $stmt = $use_mb->{object};
        unless ($base) {
            diag "No base statement at all, must inherit at least from basetest";
            return 0;
        }
        return;
    }
    return;
}

sub analyze ($filename) {
    say "Analyzing $filename";

    my $doc = PPI::Document->new($filename) or die "Could not parse $filename\n";
    my $includes = $doc->find('PPI::Statement::Include');

    my @use_mb;
    my @use_base;
    if ($includes) {
        foreach my $include (@$includes) {
            if ($include->module eq 'Mojo::Base') {
                push @use_mb, $include;
            }
            elsif ($include->module eq 'base') {
                push @use_base, $include;
            }
        }
    }

    my %use_statements;
    for my $include (@use_mb) {
        my %use = (object => $include);
        my @tokens = $include->arguments;

        for my $token (@tokens) {
            next if $token->isa('PPI::Token::Operator');
            my $content = $token->content;
            if ($token->isa('PPI::Token::Word') and $content eq '-signatures') {
                $use{signatures} = 1;
            }
            elsif ($token->isa('PPI::Token::Word') and $content eq '-strict') {
                $use{strict} = 1;
            }
            elsif ($token->isa('PPI::Token::Quote')) {
                my $string = $token->string;
                push @{ $use{base} }, $string;
            }
            elsif ($token->isa('PPI::Token::QuoteLike::Words')) {
                my @words = $token->literal;
                $use{base} = \@words;
            }
            else {
                warn __PACKAGE__.':'.__LINE__.": !!!!!!!!! Unexpected token:\n";
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$token], ['token']);
                return;
            }
        }
        $use_statements{mb} = \%use;
    }
    for my $include (@use_base) {
        my %use = (object => $include);
        my @tokens = $include->arguments;

        for my $token (@tokens) {
            next if $token->isa('PPI::Token::Operator');
            my $content = $token->content;
            if ($token->isa('PPI::Token::Quote')) {
                my $string = $token->string;
                push @{ $use{base} }, $string;
            }
            elsif ($token->isa('PPI::Token::QuoteLike::Words')) {
                my @words = $token->literal;
                $use{base} = \@words;
            }
            else {
                warn __PACKAGE__.':'.__LINE__.": !!!!!!!!! Unexpected token:\n";
                warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$token], ['token']);
                return;
            }
        }
        $use_statements{base} = \%use;
    }
    return ($doc, \%use_statements);
}
