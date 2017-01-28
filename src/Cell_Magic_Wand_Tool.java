// Theo Walker
// Max Planck Florida Institute
// naroom@gmail.com

import ij.ImagePlus;
import ij.Prefs;
import ij.gui.GenericDialog;
import ij.gui.ImageCanvas;
import ij.gui.PolygonRoi;
import ij.gui.Roi;
import ij.plugin.frame.RoiManager;
import ij.plugin.tool.PlugInTool;

import java.awt.event.MouseEvent;

import cellMagicWand.CommandLine;
import cellMagicWand.Constants;
import cellMagicWand.PolarTransform;

public class Cell_Magic_Wand_Tool extends PlugInTool {
	int minDiameter = Constants.DEFAULT_MIN_DIAMETER;
	int maxDiameter = Constants.DEFAULT_MAX_DIAMETER;
	double circumferenceSampleRate = Constants.DEFAULT_CIRCUMFERENCE_SAMPLE_RATE;
	String brightOrDarkStr = Constants.BRIGHT_CELLS;

    //default constructor is needed for plugin to load properly
    public Cell_Magic_Wand_Tool(){
    	loadPrefs();
    }
    
	public void mousePressed(ImagePlus imp, MouseEvent e) {
		try{
			ImageCanvas ic = imp.getCanvas();
			int x = ic.offScreenX(e.getX());
			int y = ic.offScreenY(e.getY());
			
			if(e.isShiftDown()){
				//Holding down Shift does multi-selection. 

				RoiManager rm;
				if (RoiManager.getInstance() == null){
					rm = new RoiManager();
					rm.runCommand("Show All");
				}
			    else{
			    	rm = RoiManager.getInstance();
			    }

				//if we're inside an existing ROI, delete it
				if(rm.getCount() > 0){
					Roi[] roiArray = rm.getRoisAsArray();
					
					for(int i = 0; i < roiArray.length; i++){	
						boolean sameZPosition = false;
						if(roiArray[i].getZPosition() != 0){
							sameZPosition = (imp.getZ() == roiArray[i].getZPosition());
						}
						else if(roiArray[i].getPosition() != 0){
							sameZPosition = (imp.getZ() == roiArray[i].getPosition());
						}
						else{
							sameZPosition = true; //this is a single image, not a stack
						}
						
						if(sameZPosition && roiArray[i].contains(x, y)){
							rm.select(i);
							rm.runCommand("Delete");
							imp.deleteRoi();
							return;
						}
					}
				}
				
				//make a new ROI, add it to the ROI manager, and update
				PolygonRoi roi = makeRoi(x,y,imp);
				rm.addRoi(roi);
				imp.setRoi(roi);
			}
			else{
				//Just draw the ROI and place it, no need for ROI manager trickery
				PolygonRoi roi = makeRoi(x,y,imp);
				imp.setRoi(roi);
			}
		}
		catch(Exception ex){
			ex.printStackTrace();
		}
		
	}
	
	public PolygonRoi makeRoi(int x, int y, ImagePlus imp){
		
		int rMin = (int) Math.round(minDiameter/2);
		int rMax = (int) Math.round(maxDiameter/2);
		
		boolean cellsAreBright = (brightOrDarkStr.equalsIgnoreCase(Constants.BRIGHT_CELLS));
		
		//Run the polar transform once to find the cell's actual radius, so we can translate circumferenceSampleRate to numThetaSamples
		PolarTransform radiusFind = new PolarTransform(imp, x, y, rMin, rMax, Constants.PIXELS_PER_R_SAMPLE, Constants.THETA_SAMPLES_FOR_RADIUS_FINDING, cellsAreBright);
		double maxRadius = radiusFind.getMaxRadius();

		int numThetaSamples = (int)Math.round(2*Math.PI*maxRadius*circumferenceSampleRate);
		if(numThetaSamples < 2)
			numThetaSamples = 2;
		
		//Now do the transform used in ROI finding
		PolarTransform pt = new PolarTransform(imp, x, y, rMin, rMax, Constants.PIXELS_PER_R_SAMPLE, numThetaSamples, cellsAreBright);
		
        //actually make the ROI
		int[][] roiPoints = pt.getEdgePointsForRoi();
		int npoints = roiPoints[0].length;
		PolygonRoi roi = new PolygonRoi(roiPoints[0], roiPoints[1], npoints, Roi.FREEROI);

		roi.setImage(imp);
		return roi;
	}

	public void showOptionsDialog() {
		loadPrefs();
        GenericDialog gd = new GenericDialog("Parameters");
		gd.addChoice("Image Type", new String[]{Constants.BRIGHT_CELLS, Constants.DARK_CELLS}, brightOrDarkStr);
		gd.addMessage("");
		gd.addNumericField("Minimum Diameter: ", minDiameter, 0);
		gd.addNumericField("Maximum Diameter: ", maxDiameter, 0);
		gd.addNumericField("Roughness: ", circumferenceSampleRate, 1);
		/* 
		gd.addMessage("");
		gd.addMessage("Created by Theo Walker at the Max Planck Florida Institute for Neuroscience.");
		gd.addMessage("theo.walker@mpfi.org");
		*/
        gd.setResizable(false);
        gd.showDialog();
        if (gd.wasCanceled()) return;

        brightOrDarkStr = gd.getNextChoice();
        minDiameter = (int)gd.getNextNumber();
        maxDiameter = (int)gd.getNextNumber();
        circumferenceSampleRate = (double)gd.getNextNumber();

        savePrefs();
	}
	
	public static void main(String[] args){
		//This plugin can be run from the command line. 
		new CommandLine(args); //everything just runs in the constructor
	}

    private void loadPrefs(){
        brightOrDarkStr=Prefs.get("CellMagicWand.brightOrDarkStr",Constants.BRIGHT_CELLS);
		minDiameter=(int)Prefs.get("CellMagicWand.minDiameter",Constants.DEFAULT_MIN_DIAMETER);
        maxDiameter=(int)Prefs.get("CellMagicWand.maxDiameter",Constants.DEFAULT_MAX_DIAMETER);
        circumferenceSampleRate=(double)Prefs.get("CellMagicWand.circumferenceSampleRate",Constants.DEFAULT_CIRCUMFERENCE_SAMPLE_RATE);
    }
    
    private void savePrefs(){
        Prefs.set("CellMagicWand.brightOrDarkStr", brightOrDarkStr);
        Prefs.set("CellMagicWand.minDiameter", minDiameter);
        Prefs.set("CellMagicWand.maxDiameter", maxDiameter);
        Prefs.set("CellMagicWand.circumferenceSampleRate", circumferenceSampleRate);
        Prefs.savePreferences();
    }
    
	public String getToolIcon() {
		return "Cff0L41a1"
				+ "L3242C54eL5292Cff0La2b2"
				+ "L2333C54eL43a3Cff0Lb3c3"
				+ "D24C54eL34b4Cff0Lc4d4"
				+ "L1525C54eL3545C234D55CaaeD65C234D75CaaeD85C023D95C54eLa5c5Cff0Ld5e5"
				+ "D16C54eL2646CaaeD56C234D66Cff0D76C023D86CaaeD96C54eLa6c6C65eDd6Cff0De6"
				+ "D17C54eL2747C234D57Cff0L6787C234D97C54eLa7c7Cff0Ld7e7"
				+ "D18C54eL2848CaaeD58C023D68Cff0D78C234D88CaaeD98C54eLa8c8Cff0Dd8"
				+ "D19C54eL2949C023D59CaaeD69C234D79CaaeD89C134D99CaaeDa9C54eLb9c9Cff0Dd9"
				+ "D1aC54eL2a8aCaaeD9aC134DaaCaaeDbaC54eDcaCff0Dda"
				+ "D1bC54eL2b9bCaaeDabC134DbbCaaeDcbCff0Ddb"
				+ "L1c2cC54eL3cacCaaeDbcC134DccCabbDdc"
				+ "Cff0L2d7dC54eL8dadCff0DbdCabbDcdC134DddCabbDed"
				+ "Cff0L7ebeCabbDdeC134DeeCabbDfe"
				+ "DefC134Dff";
	}

	public String getToolName() {
		return "Cell Magic Wand";
	}
	
	public static void print(String s){
		System.out.println(s);
	}
}
