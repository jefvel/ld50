package objects;

import elke.things.Newgrounds;
import hxd.System;
import h2d.Bitmap;
import h2d.Interactive;
import h2d.Text;
import elke.Game;
import h2d.Object;

class SocialLinks extends Object {
	public var height = 0.;
	public var width = 0.;
	public var color(default, set) = 0xFFFFFFFF;

	var instaText: Text;
	var instaIcon: Bitmap;

	var twitterText: Text;
	var twitterIcon: Bitmap;

	public function new(?p) {
		super(p);
		addButtons();
	}

	function addButtons() {
		// Socials
		var btnHeight = 12;
		if (Game.instance.usingTouch) {
			btnHeight = 24;
		}

		if (Game.instance.pixelSize == 2) {
			btnHeight = 14;
		}

		var font = hxd.Res.fonts.marumonica.toFont();

		var socialsTitle: Text = null;
		var titleText = null;
		if (titleText != null) {
			socialsTitle = new Text(font, this);
			socialsTitle.text = titleText;
			socialsTitle.alpha = 0.5;
		}

		var twitterBtn = new Interactive(1, 1, this);
		twitterIcon = new Bitmap(hxd.Res.img.twittericon.toTile(), twitterBtn);
		twitterText = new Text(font, twitterBtn);
		twitterText.x = twitterIcon.tile.width + 4;
		twitterText.y = Math.round((btnHeight - twitterText.textHeight) * 0.5 - 1);
		twitterText.text = '@jefvel';
		twitterIcon.y = Math.round((btnHeight - twitterIcon.tile.height) * 0.5 + 1);
		var b = twitterBtn.getBounds();
		twitterBtn.width = b.width;
		twitterBtn.height = btnHeight;
		twitterBtn.onClick = e -> {
			visitLink("https://twitter.com/jefvel");
		}
		
		var outAlpha = 0.8;

		twitterBtn.alpha = outAlpha;
		twitterBtn.onOver = e -> {
			twitterBtn.alpha = 1.0;
		}
		twitterBtn.onOut = e -> {
			twitterBtn.alpha = outAlpha;
		}

		if (socialsTitle != null) {
			twitterBtn.y = socialsTitle.textHeight + 4;
		}

		var instagramBtn = new Interactive(1, 1, this);
		instaIcon = new Bitmap(hxd.Res.img.instaicon.toTile(), instagramBtn);
		instaText = new Text(font, instagramBtn);
		instaText.x = instaIcon.tile.width + 4;
		instaText.y = Math.round((btnHeight - instaText.textHeight) * 0.5 - 1);
		instaText.text = '@fejvel';
		instaIcon.y = Math.round((btnHeight - instaIcon.tile.height) * 0.5 + 1);
		var b = instagramBtn.getBounds();
		instagramBtn.width = b.width;
		instagramBtn.height = btnHeight;
		instagramBtn.onClick = e -> {
			visitLink("https://instagram.com/fejvel");
		}

		instagramBtn.y = twitterBtn.y + btnHeight + 4;

		instagramBtn.alpha = outAlpha;
		instagramBtn.onOver = e -> {
			instagramBtn.alpha = 1.0;
		}

		instagramBtn.onOut = e -> {
			instagramBtn.alpha = outAlpha;
		}


		var b = getBounds();
		width = b.width;
		height = b.height;
	}

	function set_color(c) {
		twitterText.textColor = instaText.textColor = c;

		instaIcon.color.setColor(c);
		twitterIcon.color.setColor(c);

		return color = c;
	}
	
	function visitLink(url) {
		System.openURL(url);
	}
}