/**
 * This Earth Engine script provides the ability to map tree cover change over
 * Palm Oil Mill polygons and provides more in depth analytics. The script also
 * generates an Earth Engine task which exports a CSV containing  statistics
 * aboout the mills to a Cloud Storage bucket in a CSV.
 */

 var hansen = ee.Image("UMD/hansen/global_forest_change_2020_v1_8"),
 project = 'PROJECT_ID',
 // asset = 'ASSET_ID',

 errorMargin = 1e7,
 importBucket = 'PROJECT_ID-ee_export_bucket',
 table = ee.FeatureCollection("projects/"+project+"/assets/"+ asset);

//Set UI components 
/**************
* Components *
**************/
var rootPanel = ui.Panel();
var mapPanel = ui.Panel();
var outputPanel = ui.Panel();

// Configure the map panel.
var mainMap = ui.Map();
mainMap.setCenter(116.4194,0.5387, 7)
.setOptions('Satellite');

// Add map layers
// Displaying forest, loss, gain, and pixels where both loss and gain occur.
var lossImage = hansen.select(['loss']);
var gainImage = hansen.select(['gain']);
var treeCover = hansen.select(['treecover2000']);

// Use the and() method to create the lossAndGain image.
var gainAndLoss = gainImage.and(lossImage);

// Set each layer to "false" so the user can turn them on later
// Add the loss layer in red.
var lossImageLayer = ui.Map.Layer(lossImage.updateMask(lossImage),
 {palette: ['FF0000']}, 'Loss',false);

// Add the gain layer in blue.
var gainImageLayer = ui.Map.Layer(gainImage.updateMask(gainImage),
 {palette: ['0000FF']}, 'Gain',false);

// Show the loss and gain image.
var lossAndGainImageLayer = ui.Map.Layer(gainAndLoss.updateMask(gainAndLoss),
 {palette: 'FF00FF'}, 'Gain and Loss',false);

// Add these layers to our map. They will be added but not displayed
mainMap.add(lossImageLayer)
.add(gainImageLayer)
.add(lossAndGainImageLayer);
mapPanel.add(mainMap);

// Configure the output panel.

// Check boxes
var treeCover = ui.Label({
value:'Tree Cover', style: {fontWeight: 'bold', fontSize: '16px'}
});

// Create checkboxes that will allow the user to view the extent
// map for different years.
// Creating the checkbox will not do anything yet, functionality added in
// Behaviors section below
var lossCheck = ui.Checkbox('Tree cover loss').setValue(false);
var gainCheck = ui.Checkbox('Tree cover gain').setValue(false);
var lossAndGainCheck = ui.Checkbox('Tree cover gain and loss').setValue(false);

// Labels
var taskStatus = ui.Label('');
var statsHeader = ui.Label(
'Supplier Statistics',{fontWeight: 'bold', fontSize: '16px'});
var numMillsLabel = ui.Label('');
var totalChangeLabel = ui.Label('');
var avgChangeLabel = ui.Label('');
var maxChangeLabel = ui.Label('');

// Add components to panel
outputPanel.add(taskStatus)
.add(statsHeader)
.add(numMillsLabel)
.add(totalChangeLabel)
.add(avgChangeLabel)
.add(maxChangeLabel)
.add(treeCover)
.add(lossCheck)
.add(gainCheck)
.add(lossAndGainCheck);


/***********
* Styling *
***********/
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
ui.root.setLayout(ui.Panel.Layout.flow('vertical'))
rootPanel.setLayout(ui.Panel.Layout.flow('horizontal'));

/***************
* Composition *
***************/
ui.root.clear();
ui.root.add(rootPanel);
rootPanel.add(mapPanel);
rootPanel.add(outputPanel);



//Get the most recent data 
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
// Loop through assets and find the difference between today and the
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
// Set string
var desiredAssetString = desiredAsset.toLocaleString('default',{ month: 'short'})
+ '-' + desiredAsset.getDate( ) + '-' +desiredAsset.getFullYear( );

// Set asset with desired date as data to use.
table = ee.FeatureCollection(
'projects/' + project + '/assets/' + desiredAssetString);


// Add polygons to map
mainMap.addLayer(table, {}, 'default display');


//Tree cover analysis
// Get the forest loss image.
var areaImage = lossImage.multiply(ee.Image.pixelArea());
var lossYear = hansen.select(['lossyear']);

// This function computes the feature's geometry area and forest loss
// and adds them as a properties.
var addProps = function(feature) {
var stats = areaImage.reduceRegion({
reducer: ee.Reducer.sum(),
geometry: feature.geometry(),
scale: 30,
maxPixels: 1e9
});
return feature.set({areaHa: feature.geometry().area().divide(100 * 100),
 forestLoss: stats.get('loss')});
};

// Map the area and forest loss getting function over the FeatureCollection.
var propsAdded = table.map(addProps);

// Pull out interesting statistics
var totalLoss = ee.Number(propsAdded.aggregate_sum('forestLoss')).round();
var totalChange = ee.Number(propsAdded.aggregate_sum('forestLoss')).round();
var avgChange = ee.Number(propsAdded.aggregate_mean('forestLoss')).round();
var maxChange = ee.Number(propsAdded.aggregate_max('forestLoss')).round();
var changeStats = propsAdded.aggregate_stats('forestLoss');
var numMills = ee.Number(changeStats.get('total_count'));


//Add checkbox functionality for map layers and set UI panel info
// Set info in UI panel
numMills.evaluate(function callback(value) {
numMillsLabel.setValue("Number of mills: " + value + " mills");
});

avgChange.evaluate(function callback(value) {
var valueHA = value / 10000
avgChangeLabel.setValue("Average tree cover change: " + valueHA + " HA");
});

totalChange.evaluate(function callback(value) {
var valueHA = value / 10000
totalChangeLabel.setValue("Total tree cover change: " + valueHA + " HA");
});

maxChange.evaluate(function callback(value) {
var valueHA = value / 10000
maxChangeLabel.setValue("Max tree cover change: " + valueHA + " HA");
});


// Set task status
taskStatus.setValue("Data Import Status : " + desiredAssetString)

// Create a function for each checkbox so that clicking the checkbox turns
// on layers of interest.

// Loss
var doLossCheckbox = function() {
lossCheck.onChange(function(checked){
lossImageLayer.setShown(checked);
});
}
doLossCheckbox();

// Gain
var doGainCheckbox = function() {
gainCheck.onChange(function(checked){
gainImageLayer.setShown(checked);
});
}
doGainCheckbox();

// Loss and Gain
var doLossAndGainCheckbox = function() {
lossAndGainCheck.onChange(function(checked){
lossAndGainImageLayer.setShown(checked);
});
}
doLossAndGainCheckbox();



//Add export task
// Export a CSV file to Cloud Storage.
var aggregateFeature = ee.FeatureCollection(table.geometry(), changeStats);
var filename = 'changeStats' + Date()
Export.table.toCloudStorage({
collection: aggregateFeature,
description:'advancedAnalyticsToCloudStorage',
bucket: importBucket,
fileNamePrefix: filename ,
fileFormat: 'CSV'
});

