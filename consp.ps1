param($cmd)

# registry reference:
#     http://technet.microsoft.com/en-us/library/cc978570.aspx
#
# setting NT_CONSOLE_PROPS (not implemented):
#     http://sourcewarp.blogspot.com.au/2012/06/windows-powershell-shortcut-ishelllink.html

$colors = 'black,blue,green,aqua,red,purple,yellow,white,gray,light_blue,light_green,light_aqua,light_red,light_purple,light_yellow,bright_white'.split(',')

$map = @{
	'FontFamily'=@('font_true_type', 'font_type')
	'FaceName'=@('font_face', 'string')
	'FontSize'=@('font_size', 'dim')
	'FontWeight'=@('font_weight','int')
	'CursorSize'=@('cursor_size','cursor')
	'QuickEdit'=@('quick_edit', 'bool')
	'ScreenBufferSize'=@('screen_buffer_size', 'dim')
	'WindowSize'=@('window_size', 'dim')
	'PopupColors'=@('popup_colors', 'fg_bg')
	'ScreenColors'=@('screen_colors', 'fg_bg')
	'FullScreen'=@('fullscreen','bool')
	'HistoryBufferSize'=@('command_history_length','int')
	'NumberOfHistoryBuffers'=@('num_history_buffers','int')
	'InsertMode'=@('insert_mode','bool')
	'LoadConIme'=@('load_console_IME','bool')
}
for($i=0;$i -lt $colors.length;$i++) {
	$map.add("ColorTable$($i.tostring('00'))", @($colors[$i],'color'))
}

function get_json {
	$props = @{}
	(gp hkcu:\console).psobject.properties | sort name |% {
		$name,$type = $map[$_.name]
		if($name) {
			$props.add($name, (decode $_.value $type))
		}
	}

	$props | convertto-json
}

function decode($val, $type) {
	switch($type) {
		'bool' { [bool]$val }
		'color' {
			$bytes = [bitconverter]::getbytes($val)
			[array]::reverse($bytes)
			$int = [bitconverter]::toint32($bytes, 0)

			'#' + $int.tostring('x8').substring(0,6)
		}
		'cursor' {
			switch($val) {
				0x19 { 'small' }
				0x32 { 'small' }
				0x64 { 'small' }
			}
		}
		'fg_bg' {
			$hex = $val.tostring('x2')
			$bg_i = [convert]::toint32($hex[0],16)
			$fg_i = [convert]::toint32($hex[1],16)
			$bg = $colors[$bg_i]
			$fg = $colors[$fg_i]
			"$fg,$bg"
		}
		'font_type' { }
		'int' { $val }
		'string' { $val }
		'dim' {
			$bytes = [bitconverter]::getbytes($val)
			$width = [bitconverter]::toint16($bytes[0..2], 0)
			$height = [bitconverter]::toint16($bytes, 2)
			"$($width)x$($height)"
		}
	}
}

function encode($val, $type) {
	switch($type) {
		default { 'NOT IMPLEMENTED'}
	}
}

get_json
#encode $true 'bool'