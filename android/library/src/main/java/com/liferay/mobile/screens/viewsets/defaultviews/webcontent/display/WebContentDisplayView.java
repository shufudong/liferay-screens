/**
 * Copyright (c) 2000-present Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */

package com.liferay.mobile.screens.viewsets.defaultviews.webcontent.display;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.widget.FrameLayout;
import android.widget.ProgressBar;

import com.liferay.mobile.screens.R;
import com.liferay.mobile.screens.base.BaseScreenlet;
import com.liferay.mobile.screens.context.LiferayServerContext;
import com.liferay.mobile.screens.webcontent.WebContent;
import com.liferay.mobile.screens.util.LiferayLogger;
import com.liferay.mobile.screens.webcontent.display.WebContentDisplayScreenlet;
import com.liferay.mobile.screens.webcontent.display.view.WebContentDisplayViewModel;

/**
 * @author Silvio Santos
 */
public class WebContentDisplayView extends FrameLayout
	implements WebContentDisplayViewModel, View.OnTouchListener {

	public WebContentDisplayView(Context context) {
		super(context);
	}

	public WebContentDisplayView(Context context, AttributeSet attributes) {
		super(context, attributes);
	}

	public WebContentDisplayView(Context context, AttributeSet attributes, int defaultStyle) {
		super(context, attributes, defaultStyle);
	}

	@Override
	public void showStartOperation(String actionName) {
		if (_progressBar != null) {
			_progressBar.setVisibility(View.VISIBLE);
		}
		if (_webView != null) {
			_webView.setVisibility(View.GONE);
		}
	}

	@Override
	public void showFinishOperation(String actionName) {
		throw new AssertionError();
	}

	@Override
	public void showFinishOperation(WebContent webContent) {
		if (_progressBar != null) {
			_progressBar.setVisibility(View.GONE);
		}
		if (_webView != null) {
			_webView.setVisibility(View.VISIBLE);

			LiferayLogger.i("article loaded: " + webContent);

			String styledHtml = STYLES + "<div class=\"MobileCSS\">" + webContent.getHtml() + "</div>";

			//TODO check encoding
			_webView.loadDataWithBaseURL(
				LiferayServerContext.getServer(), styledHtml, "text/html", "utf-8",
				null);
		}
	}

	@Override
	public void showFailedOperation(String actionName, Exception e) {
		if (_progressBar != null) {
			_progressBar.setVisibility(View.GONE);
		}
		if (_webView != null) {
			_webView.setVisibility(View.VISIBLE);
		}

		LiferayLogger.e(getContext().getString(R.string.loading_article_error), e);
	}

	@Override
	public BaseScreenlet getScreenlet() {
		return _screenlet;
	}

	@Override
	public void setScreenlet(BaseScreenlet screenlet) {
		_screenlet = screenlet;
	}

	@Override
	public boolean onTouch(View v, MotionEvent event) {
		WebView.HitTestResult result = _webView.getHitTestResult();
		((WebContentDisplayScreenlet) getScreenlet()).onWebContentClicked(result, event);
		return false;
	}

	@Override
	protected void onFinishInflate() {
		super.onFinishInflate();

		_webView = (WebView) findViewById(R.id.liferay_webview);
		_progressBar = (ProgressBar) findViewById(R.id.liferay_webview_progress);
	}

	@Override
	protected void onAttachedToWindow() {
		super.onAttachedToWindow();

		WebContentDisplayScreenlet screenlet = (WebContentDisplayScreenlet) getScreenlet();
		if (_webView != null) {
			if (screenlet.isJavascriptEnabled()) {
				_webView.getSettings().setJavaScriptEnabled(true);
				_webView.setWebChromeClient(new WebChromeClient());
			}
			_webView.setOnTouchListener(this);
		}
	}

	protected WebView _webView;
	protected ProgressBar _progressBar;

	private static final String STYLES =
		"<style>" +
			".MobileCSS {padding: 4%; width: 92%;} " +
			".MobileCSS, .MobileCSS span, .MobileCSS p, .MobileCSS h1, " +
			".MobileCSS h2, .MobileCSS h3{ " +
			"font-size: 110%; font-weight: 200;" +
			"font-family: \"Helvetica Neue\", Helvetica, Arial, sans-serif;} " +
			".MobileCSS img { width: 100% !important; } " +
			".span2, .span3, .span4, .span6, .span8, .span10 { width: 100%; }" +
			"</style>";

	private BaseScreenlet _screenlet;
}