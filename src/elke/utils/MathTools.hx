package elke.utils;

class MathTools {
	static public function clamp(a:Float, min: Float, max: Float):Float {
		if (a < min) {
			return min;
		}
		if (a > max) {
			return max;
		}
		return a;
	}

	static public function angleBetween(radian: Float, toRadian: Float): Float {
		var diff = ( toRadian - radian + Math.PI ) % (Math.PI * 2) - Math.PI;
		diff = diff < -Math.PI ? diff + Math.PI * 2 : diff;
		diff *= 0.5;
		return diff;
	}

	public static function toFixed(number:Float, ?precision=2): Float {
		number *= Math.pow(10, precision);
		return Math.round(number) / Math.pow(10, precision);
	}

	static function formatMoneyString(s : String) {
		var r = ~/(\d)(?=(\d{3})+(?!\d))/g;
		return r.replace(s, "$1 ");
	}

	static public function toMoneyString(a: Int) : String {
		return formatMoneyString('$a');
	}

	static public function toMoneyStringFloat(x: Float): String {
		var parts = '${x.toFixed()}'.split(".");
		parts[0] = formatMoneyString(parts[0]);
		if (parts.length == 1) parts.push('00');
		return parts.join(".");
	}

	static public function toTimeString(x: Float): String {
		var minutes = Math.floor(x / 60);
		var seconds = x - minutes * 60;
		var extraZero = minutes < 10 ? '0' : '';
		var extraSecondZero = seconds < 10 ? '0' : '';
		var hundredsSplit = '${seconds}'.split('.');
		var hundreds = "000";
		if (hundredsSplit.length > 1) {
			hundreds = '${hundredsSplit[1].substr(0, 3)}';
			while(hundreds.length < 3){
				hundreds = "0" + hundreds;
			}
		}

		return '$extraZero$minutes:$extraSecondZero${Math.floor(seconds)}:$hundreds';
	}
}
