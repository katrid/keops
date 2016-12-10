$(document).ready(function () {

  var config = {
    defaultAnimationEffect: 'fadeIn'
  };

  var bodyResize = function () {
    var b = $('body');
    if ($(this).width() <= 768) b.addClass('page-small');
    else {
      b.removeClass('page-small');
      b.removeClass('show-left-menu');
    }
  };

  var adjustContentHeight = function () {
    // Get and set current height
    var headerH = $('body>nav.navbar').height();
    var leftMenu = $("#left-menu").height();
    var mContent = $('#main-content');
    var content = mContent.height();

    var h = Math.max($("#left-menu").height(), mContent.height());
    mContent.css("min-height", h + 'px');
  };

  bodyResize();
  adjustContentHeight();

  $('.hide-left-menu').click(function (event) {
    event.preventDefault();
    if ($(window).width() <= 768) $('body').toggleClass('show-left-menu');
    else $('body').toggleClass('hide-left-menu');
  });

  $(window).bind("resize", function () {
    bodyResize();
    setTimeout(function () {
      adjustContentHeight();
    }, 300);
  });

  // initialize menu


  // initialize tooltips
  $('[data-toggle="tooltip"]').tooltip({container: 'body'});

  // initialize animated elements
  if (config.defaultAnimationEffect) {
    $('.dropdown-menu:not(.animated)').addClass('animated').addClass(config.defaultAnimationEffect);
    $('.content').addClass('animated fadeIn');
  }

  // start charts plugins
  if ($.fn.sparkline) {

    // variable declearations:

    var barColor,
      sparklineHeight,
      sparklineBarWidth,
      sparklineBarSpacing,
      sparklineNegBarColor,
      sparklineStackedColor,
      thisLineColor,
      thisLineWidth,
      thisFill,
      thisSpotColor,
      thisMinSpotColor,
      thisMaxSpotColor,
      thishighlightSpotColor,
      thisHighlightLineColor,
      thisSpotRadius,
      pieColors,
      pieWidthHeight,
      pieBorderColor,
      pieOffset,
      thisBoxWidth,
      thisBoxHeight,
      thisBoxRaw,
      thisBoxTarget,
      thisBoxMin,
      thisBoxMax,
      thisShowOutlier,
      thisIQR,
      thisBoxSpotRadius,
      thisBoxLineColor,
      thisBoxFillColor,
      thisBoxWhisColor,
      thisBoxOutlineColor,
      thisBoxOutlineFill,
      thisBoxMedianColor,
      thisBoxTargetColor,
      thisBulletHeight,
      thisBulletWidth,
      thisBulletColor,
      thisBulletPerformanceColor,
      thisBulletRangeColors,
      thisDiscreteHeight,
      thisDiscreteWidth,
      thisDiscreteLineColor,
      thisDiscreteLineHeight,
      thisDiscreteThrushold,
      thisDiscreteThrusholdColor,
      thisTristateHeight,
      thisTristatePosBarColor,
      thisTristateNegBarColor,
      thisTristateZeroBarColor,
      thisTristateBarWidth,
      thisTristateBarSpacing,
      thisZeroAxis,
      thisBarColor,
      sparklineWidth,
      sparklineValue,
      sparklineValueSpots1,
      sparklineValueSpots2,
      thisLineWidth1,
      thisLineWidth2,
      thisLineColor1,
      thisLineColor2,
      thisSpotRadius1,
      thisSpotRadius2,
      thisMinSpotColor1,
      thisMaxSpotColor1,
      thisMinSpotColor2,
      thisMaxSpotColor2,
      thishighlightSpotColor1,
      thisHighlightLineColor1,
      thishighlightSpotColor2,
      thisFillColor1,
      thisFillColor2;

    $('.sparkline:not(:has(>canvas))').each(function () {
      var $this = $(this),
        sparklineType = $this.data('sparkline-type') || 'bar';

      // BAR CHART
      if (sparklineType == 'bar') {

        barColor = $this.data('sparkline-bar-color') || $this.css('color') || '#B4CAD3';
        sparklineHeight = $this.data('sparkline-height') || '26px';
        sparklineBarWidth = $this.data('sparkline-barwidth') || 5;
        sparklineBarSpacing = $this.data('sparkline-barspacing') || 2;
        sparklineNegBarColor = $this.data('sparkline-negbar-color') || '#A90329';
        sparklineStackedColor = $this.data('sparkline-barstacked-color') || ["#A90329", "#0099c6", "#98AA56", "#da532c", "#4490B1", "#6E9461", "#990099", "#B4CAD3"];

        $this.sparkline('html', {
          barColor: barColor,
          type: sparklineType,
          height: sparklineHeight,
          barWidth: sparklineBarWidth,
          barSpacing: sparklineBarSpacing,
          stackedBarColor: sparklineStackedColor,
          negBarColor: sparklineNegBarColor,
          zeroAxis: 'false'
        });

        $this = null;

      }

      // LINE CHART
      if (sparklineType == 'line') {

        sparklineHeight = $this.data('sparkline-height') || '20px';
        sparklineWidth = $this.data('sparkline-width') || '90px';
        thisLineColor = $this.data('sparkline-line-color') || $this.css('color') || '#0000f0';
        thisLineWidth = $this.data('sparkline-line-width') || 1;
        thisFill = $this.data('fill-color') || '#c0d0f0';
        thisSpotColor = $this.data('sparkline-spot-color') || '#f08000';
        thisMinSpotColor = $this.data('sparkline-minspot-color') || '#ed1c24';
        thisMaxSpotColor = $this.data('sparkline-maxspot-color') || '#f08000';
        thishighlightSpotColor = $this.data('sparkline-highlightspot-color') || '#50f050';
        thisHighlightLineColor = $this.data('sparkline-highlightline-color') || 'f02020';
        thisSpotRadius = $this.data('sparkline-spotradius') || 1.5;
        thisChartMinYRange = $this.data('sparkline-min-y') || 'undefined';
        thisChartMaxYRange = $this.data('sparkline-max-y') || 'undefined';
        thisChartMinXRange = $this.data('sparkline-min-x') || 'undefined';
        thisChartMaxXRange = $this.data('sparkline-max-x') || 'undefined';
        thisMinNormValue = $this.data('min-val') || 'undefined';
        thisMaxNormValue = $this.data('max-val') || 'undefined';
        thisNormColor = $this.data('norm-color') || '#c0c0c0';
        thisDrawNormalOnTop = $this.data('draw-normal') || false;

        $this.sparkline('html', {
          type: 'line',
          width: sparklineWidth,
          height: sparklineHeight,
          lineWidth: thisLineWidth,
          lineColor: thisLineColor,
          fillColor: thisFill,
          spotColor: thisSpotColor,
          minSpotColor: thisMinSpotColor,
          maxSpotColor: thisMaxSpotColor,
          highlightSpotColor: thishighlightSpotColor,
          highlightLineColor: thisHighlightLineColor,
          spotRadius: thisSpotRadius,
          chartRangeMin: thisChartMinYRange,
          chartRangeMax: thisChartMaxYRange,
          chartRangeMinX: thisChartMinXRange,
          chartRangeMaxX: thisChartMaxXRange,
          normalRangeMin: thisMinNormValue,
          normalRangeMax: thisMaxNormValue,
          normalRangeColor: thisNormColor,
          drawNormalOnTop: thisDrawNormalOnTop

        });

        $this = null;

      }

      if (sparklineType == 'pie') {

        pieColors = $this.data('sparkline-piecolor') || ["#B4CAD3", "#4490B1", "#98AA56", "#da532c", "#6E9461", "#0099c6", "#990099", "#717D8A"];
        pieWidthHeight = $this.data('sparkline-piesize') || 90;
        pieBorderColor = $this.data('border-color') || '#45494C';
        pieOffset = $this.data('sparkline-offset') || 0;

        $this.sparkline('html', {
          type: 'pie',
          width: pieWidthHeight,
          height: pieWidthHeight,
          tooltipFormat: '<span style="color: {{color}}">&#9679;</span> ({{percent.1}}%)',
          sliceColors: pieColors,
          borderWidth: 1,
          offset: pieOffset,
          borderColor: pieBorderColor
        });

        $this = null;

      }

      // BOX PLOT
      if (sparklineType == 'box') {

        thisBoxWidth = $this.data('sparkline-width') || 'auto';
        thisBoxHeight = $this.data('sparkline-height') || 'auto';
        thisBoxRaw = $this.data('sparkline-boxraw') || false;
        thisBoxTarget = $this.data('sparkline-targetval') || 'undefined';
        thisBoxMin = $this.data('sparkline-min') || 'undefined';
        thisBoxMax = $this.data('sparkline-max') || 'undefined';
        thisShowOutlier = $this.data('sparkline-showoutlier') || true;
        thisIQR = $this.data('sparkline-outlier-iqr') || 1.5;
        thisBoxSpotRadius = $this.data('sparkline-spotradius') || 1.5;
        thisBoxLineColor = $this.css('color') || '#000000';
        thisBoxFillColor = $this.data('fill-color') || '#c0d0f0';
        thisBoxWhisColor = $this.data('sparkline-whis-color') || '#000000';
        thisBoxOutlineColor = $this.data('sparkline-outline-color') || '#303030';
        thisBoxOutlineFill = $this.data('sparkline-outlinefill-color') || '#f0f0f0';
        thisBoxMedianColor = $this.data('sparkline-outlinemedian-color') || '#f00000';
        thisBoxTargetColor = $this.data('sparkline-outlinetarget-color') || '#40a020';

        $this.sparkline('html', {
          type: 'box',
          width: thisBoxWidth,
          height: thisBoxHeight,
          raw: thisBoxRaw,
          target: thisBoxTarget,
          minValue: thisBoxMin,
          maxValue: thisBoxMax,
          showOutliers: thisShowOutlier,
          outlierIQR: thisIQR,
          spotRadius: thisBoxSpotRadius,
          boxLineColor: thisBoxLineColor,
          boxFillColor: thisBoxFillColor,
          whiskerColor: thisBoxWhisColor,
          outlierLineColor: thisBoxOutlineColor,
          outlierFillColor: thisBoxOutlineFill,
          medianColor: thisBoxMedianColor,
          targetColor: thisBoxTargetColor

        });

        $this = null;

      }

      // BULLET
      if (sparklineType == 'bullet') {

        var thisBulletHeight = $this.data('sparkline-height') || 'auto';
        thisBulletWidth = $this.data('sparkline-width') || 2;
        thisBulletColor = $this.data('sparkline-bullet-color') || '#ed1c24';
        thisBulletPerformanceColor = $this.data('sparkline-performance-color') || '#3030f0';
        thisBulletRangeColors = $this.data('sparkline-bulletrange-color') || ["#d3dafe", "#a8b6ff", "#7f94ff"];

        $this.sparkline('html', {

          type: 'bullet',
          height: thisBulletHeight,
          targetWidth: thisBulletWidth,
          targetColor: thisBulletColor,
          performanceColor: thisBulletPerformanceColor,
          rangeColors: thisBulletRangeColors

        });

        $this = null;

      }

      // DISCRETE
      if (sparklineType == 'discrete') {

        thisDiscreteHeight = $this.data('sparkline-height') || 26;
        thisDiscreteWidth = $this.data('sparkline-width') || 50;
        thisDiscreteLineColor = $this.css('color');
        thisDiscreteLineHeight = $this.data('sparkline-line-height') || 5;
        thisDiscreteThrushold = $this.data('sparkline-threshold') || 'undefined';
        thisDiscreteThrusholdColor = $this.data('sparkline-threshold-color') || '#ed1c24';

        $this.sparkline('html', {

          type: 'discrete',
          width: thisDiscreteWidth,
          height: thisDiscreteHeight,
          lineColor: thisDiscreteLineColor,
          lineHeight: thisDiscreteLineHeight,
          thresholdValue: thisDiscreteThrushold,
          thresholdColor: thisDiscreteThrusholdColor

        });

        $this = null;

      }

      // TRISTATE
      if (sparklineType == 'tristate') {

        thisTristateHeight = $this.data('sparkline-height') || 26;
        thisTristatePosBarColor = $this.data('sparkline-posbar-color') || '#60f060';
        thisTristateNegBarColor = $this.data('sparkline-negbar-color') || '#f04040';
        thisTristateZeroBarColor = $this.data('sparkline-zerobar-color') || '#909090';
        thisTristateBarWidth = $this.data('sparkline-barwidth') || 5;
        thisTristateBarSpacing = $this.data('sparkline-barspacing') || 2;
        thisZeroAxis = $this.data('sparkline-zeroaxis') || false;

        $this.sparkline('html', {

          type: 'tristate',
          height: thisTristateHeight,
          posBarColor: thisBarColor,
          negBarColor: thisTristateNegBarColor,
          zeroBarColor: thisTristateZeroBarColor,
          barWidth: thisTristateBarWidth,
          barSpacing: thisTristateBarSpacing,
          zeroAxis: thisZeroAxis

        });

        $this = null;

      }

      //COMPOSITE: BAR
      if (sparklineType == 'compositebar') {

        sparklineHeight = $this.data('sparkline-height') || '20px';
        sparklineWidth = $this.data('sparkline-width') || '100%';
        sparklineBarWidth = $this.data('sparkline-barwidth') || 3;
        thisLineWidth = $this.data('sparkline-line-width') || 1;
        thisLineColor = $this.data('data-sparkline-linecolor') || '#ed1c24';
        thisBarColor = $this.data('data-sparkline-barcolor') || '#333333';

        $this.sparkline($this.data('sparkline-bar-val'), {

          type: 'bar',
          width: sparklineWidth,
          height: sparklineHeight,
          barColor: thisBarColor,
          barWidth: sparklineBarWidth
          //barSpacing: 5

        });

        $this.sparkline($this.data('sparkline-line-val'), {

          width: sparklineWidth,
          height: sparklineHeight,
          lineColor: thisLineColor,
          lineWidth: thisLineWidth,
          composite: true,
          fillColor: false

        });

        $this = null;

      }

      //COMPOSITE: LINE
      if (sparklineType == 'compositeline') {

        sparklineHeight = $this.data('sparkline-height') || '20px';
        sparklineWidth = $this.data('sparkline-width') || '90px';
        sparklineValue = $this.data('sparkline-bar-val');
        sparklineValueSpots1 = $this.data('sparkline-bar-val-spots-top') || null;
        sparklineValueSpots2 = $this.data('sparkline-bar-val-spots-bottom') || null;
        thisLineWidth1 = $this.data('sparkline-line-width-top') || 1;
        thisLineWidth2 = $this.data('sparkline-line-width-bottom') || 1;
        thisLineColor1 = $this.data('sparkline-color-top') || '#333333';
        thisLineColor2 = $this.data('sparkline-color-bottom') || '#ed1c24';
        thisSpotRadius1 = $this.data('sparkline-spotradius-top') || 1.5;
        thisSpotRadius2 = $this.data('sparkline-spotradius-bottom') || thisSpotRadius1;
        thisSpotColor = $this.data('sparkline-spot-color') || '#f08000';
        thisMinSpotColor1 = $this.data('sparkline-minspot-color-top') || '#ed1c24';
        thisMaxSpotColor1 = $this.data('sparkline-maxspot-color-top') || '#f08000';
        thisMinSpotColor2 = $this.data('sparkline-minspot-color-bottom') || thisMinSpotColor1;
        thisMaxSpotColor2 = $this.data('sparkline-maxspot-color-bottom') || thisMaxSpotColor1;
        thishighlightSpotColor1 = $this.data('sparkline-highlightspot-color-top') || '#50f050';
        thisHighlightLineColor1 = $this.data('sparkline-highlightline-color-top') || '#f02020';
        thishighlightSpotColor2 = $this.data('sparkline-highlightspot-color-bottom') ||
          thishighlightSpotColor1;
        thisHighlightLineColor2 = $this.data('sparkline-highlightline-color-bottom') ||
          thisHighlightLineColor1;
        thisFillColor1 = $this.data('sparkline-fillcolor-top') || 'transparent';
        thisFillColor2 = $this.data('sparkline-fillcolor-bottom') || 'transparent';

        $this.sparkline(sparklineValue, {

          type: 'line',
          spotRadius: thisSpotRadius1,

          spotColor: thisSpotColor,
          minSpotColor: thisMinSpotColor1,
          maxSpotColor: thisMaxSpotColor1,
          highlightSpotColor: thishighlightSpotColor1,
          highlightLineColor: thisHighlightLineColor1,

          valueSpots: sparklineValueSpots1,

          lineWidth: thisLineWidth1,
          width: sparklineWidth,
          height: sparklineHeight,
          lineColor: thisLineColor1,
          fillColor: thisFillColor1

        });

        $this.sparkline($this.data('sparkline-line-val'), {

          type: 'line',
          spotRadius: thisSpotRadius2,
          spotColor: thisSpotColor,
          minSpotColor: thisMinSpotColor2,
          maxSpotColor: thisMaxSpotColor2,
          highlightSpotColor: thishighlightSpotColor2,
          highlightLineColor: thisHighlightLineColor2,
          valueSpots: sparklineValueSpots2,
          lineWidth: thisLineWidth2,
          width: sparklineWidth,
          height: sparklineHeight,
          lineColor: thisLineColor2,
          composite: true,
          fillColor: thisFillColor2
        });
        $this = null;
      }
    });
  }

});

