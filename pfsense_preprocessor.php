#!/usr/local/bin/php -q
<?php
/* $Id$ */
/*
	filterparser.php
	part of pfSesne by Scott Ullrich
	originally based on m0n0wall (http://m0n0.ch/wall)

	Copyright (C) 2009 Jim Pingle <myfirstname>@<mylastname>.org
	Copyright (C) 2013-2015 Electric Sheep Fencing, LP
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
	AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
	AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.

 A quick CLI log parser. 

 Modified to recover ICMP type and code for DSHIELD

 Examples: 
	clog /var/log/filter.log | tail -50 | /usr/local/www/filterparser.php
	clog -f /var/log/filter.log | /usr/local/www/filterparser.php
*/
/*
	pfSense_MODULE:	logs
*/

include_once("functions.inc");
include_once("filter_log.inc");

$log = fopen("php://stdin", "r");
$lastline = "";
while(!feof($log)) { 
	$line = fgets($log);
	$line = rtrim($line);
	$flent = parse_filter_line(trim($line));
	if ($flent != "") {
		switch ($flent['proto']) {
		case "TCP":
			$flags = (($flent['proto'] == "TCP") && !empty($flent['tcpflags'])) ? ":" . $flent['tcpflags'] : "";
			echo "{$flent['time']} {$flent['act']} {$flent['realint']} {$flent['proto']}{$flags} {$flent['src']} {$flent['dst']}\n";
			break;
		case "ICMP":
		case "ICMP6":
		case "ICMPv6":
			$type = "???";
			$code = "???";
			switch ($flent['icmp_type']) {
			case 'request':
				$type = "8";
				$code = "0";
				break;
			case 'reply':
				$type = "0";
				$code = "0";
				break;
			case 'unreachproto':
				$type = "3";
				$code = "2";
				break;
			case 'unreachport':
				$type = "3";
				$code = "3";
				break;
			case 'unreach':
				$type = "3";
				break;
			case 'timexceed':
				$type = "11";
				$code = "0";
				break;
			case 'paramprob':
				$type = "12";
				break;
			case 'redirect':
				$type = "5";
				break;
			case 'maskreply':
				$type = "18";
				$code = "0";
				break;
			case 'needfrag':
				$type = "3";
				$code = "4";
				break;
			case 'tstamp':
				$type = "13";
				$code = "0";
				break;
			case 'tstampreply':
				$type = "14";
				$code = "0";
				break;
			}
			echo "{$flent['time']} {$flent['act']} {$flent['realint']} {$flent['proto']} {$flent['src']}:{$type} {$flent['dst']}:{$code}\n";
			break;
		default:
			echo "{$flent['time']} {$flent['act']} {$flent['realint']} {$flent['proto']} {$flent['src']} {$flent['dst']}\n";
			break;
		}
		$flent = "";
	}
}
fclose($log); ?>
