/**
 * This Earth Engine script runs light tree cover analysis on polygons
 * representing Palm Oil Mills in Indonesia and produces a dashboard containing
 * information about the mills. The dashboard contains a map that displays
 * the mills and an information panel displays light analysis and a
 * a link to a more advanced analytics environment.
 */

 var hansen = ee.Image("UMD/hansen/global_forest_change_2020_v1_8"),
 project = 'rick-geo-enterprise',
 asset =  'may-06-2022',
 table = ee.FeatureCollection("projects/"+project+"/assets/"+ asset),
 errorMargin = 1e7,
 advancedAnalyticsLink = 'https://code.earthengine.google.com/49ed33a38712475cb3755562e04782dd';
 
 

/**************
* Components *
**************/
var rootPanel = ui.Panel();  // Highest-level container.
var title = ui.Label("Cymbal Palm Oil Dashboard");
var mapPanel = ui.Panel();
var outputPanel = ui.Panel([],'',{'backgroundColor' : 'grey'});

// Configure the map panel.
var mainMap = ui.Map();
mainMap.setCenter(116.4194,0.5387, 6);
mapPanel.add(mainMap);

// Configure the output panel.
var advancedScriptLink = ui.Label(
'Advanced Analytics',{'color': 'black','backgroundColor':'D3D3D3',
'border': '2px solid black', 'padding':'4px'}, advancedAnalyticsLink);
var purposeHeader = ui.Label('Purpose', {fontWeight: 'bold'});
var statsHeader = ui.Label('Key Insights', {fontWeight: 'bold'});
var advancedAnalyticsHeader = ui.Label('Advanced Analytics', {fontWeight: 'bold'});
var advancedAnalyticsText = ui.Label(
'Please click the button below for more' + ' comprehensive analysis tools.');
var avgLossLabel = ui.Label('Average tree cover change in plantation areas is: ');
var totalLossLabel = ui.Label('Total tree cover change in plantation areas is: ');
var taskStatus = ui.Label('Data Import Status : ');
var taskDate = ui.Label('');
var textOutput = ui.Label('This dashboard provides information about the Plam Oil suppliers for the' +
' Cymbal Cookie Night Brand. The map on the left plots the boundaries of Palm' +
' Oil Plantations that partnering mills are likely sourcing from.');
var citation = ui.Label('[1] Source : Hansen, Potapov, Moore, Hancher et al.',
{textAlign: 'right'},'https://www.science.org/doi/10.1126/science.1244693');
outputPanel.add(taskStatus)
.add(taskDate)
.add(statsHeader)
.add(totalLossLabel)
.add(avgLossLabel)
.add(advancedAnalyticsHeader)
.add(advancedAnalyticsText)
.add(advancedScriptLink)
.add(purposeHeader)
.add(textOutput)
.add(citation);

/***********
* Styling *
***********/
title.style().set({
height: '10%',
width: '100%',
margin: 0,
textAlign: 'center',
fontSize: '24px',
backgroundColor: '444444',
color: 'white'
});
rootPanel.style().set({
height: '100%',
width: '100%'
});
mapPanel.style().set({
height: '90%',
width: '60%',
});
outputPanel.style().set({
height: '90%',
width: '50%',
backgroundColor: 'white',
});

// Configure the layouts for how the panels flow together.
ui.root.setLayout(ui.Panel.Layout.flow('vertical'));
rootPanel.setLayout(ui.Panel.Layout.flow('horizontal'));

/***************
* Composition *
***************/
ui.root.clear();
ui.root.add(title);
ui.root.add(rootPanel);
rootPanel.add(mapPanel);
rootPanel.add(outputPanel);



/* get the most data
/**********************
* Behaviors and data *
**********************/
// Get the current date
var currentDate = Date.now();
// List the assets (all with same date format as asset id)
var assetList = ee.data.listBuckets('projects/' + project);
var assets = assetList['assets'];
// Initialize variables
var smallestDiff = 0;
var desiredAsset = new Date();
// Loop thorugh assets and find the difference between today and the
// date of the asset
for (var asset in assets) {
// Set asset name is now the date
var id = assets[asset]['name'];
var assetName = id.split("/")[3];
// Create a date object
var assetDate = new Date(assetName);
// Find the difference between the date of the asset and the current date
var diff = currentDate - assetDate;
// Reset the smallestDiff if this is the first asset or if this asset is more
// recent than the current most recent asset
if ((asset == '0') || (diff < smallestDiff)) {
 smallestDiff = diff
 desiredAsset = assetDate
}
}
var desiredAssetString =
desiredAsset.toLocaleString('default', { month: 'short' }) +
'-' + desiredAsset.getDate( ) + '-' + desiredAsset.getFullYear( );

// Set asset with desired date as data to use.
table = ee.FeatureCollection(
'projects/' + project + '/assets/' + desiredAssetString);

// Add polygons to map.
mainMap.addLayer(table, {}, 'default display');


//Tree cover analysis
// Get the forest loss image.
var lossImage = hansen.select(['loss']);
var areaImage = lossImage.multiply(ee.Image.pixelArea());
var lossYear = hansen.select(['lossyear']);

// This function computes the feature's geometry area and forest loss and
// adds them as a properties.
var addProps = function(feature) {
var stats = areaImage.reduceRegion({
 reducer: ee.Reducer.sum(),
 geometry: feature.geometry(),
 scale: 30,
 maxPixels: 1e9
});
return feature.set( {areaHa: feature.geometry(errorMargin).area().divide(100 * 100),
 forestLoss: stats.get('loss')});
};


//Populate  UI with data 
// Map the area and forest loss getting function over the FeatureCollection.
var propsAdded = table.map(addProps);
var totalLoss = propsAdded.aggregate_sum('forestLoss').round();
var avgLoss = propsAdded.aggregate_mean('forestLoss').round();

// Set info in UI panel
avgLoss.evaluate(function callback(value) {
var valueHA = value / 10000
avgLossLabel.setValue(
 "Average tree cover change in plantation" +
 " areas is: " + valueHA + " HA [1]");
});

totalLoss.evaluate(function callback(value) {
var valueHA = value / 10000
totalLossLabel.setValue(
 "Total tree cover change in plantation" +
 " areas is: " + valueHA + " HA [1]");
});

taskStatus.setValue("Data Import Status : " + desiredAssetString)
