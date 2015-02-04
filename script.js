// Scale molecule to a consistent size on canvas
function scaleMol(mol) {
    var length = 30;
    var avBondLength = getAverageBondLength(mol);
    if (avBondLength !== 0) {
        var scale = length / avBondLength;
        for (var i = 0, ii = mol.atoms.length; i < ii; i++) {
            mol.atoms[i].x *= scale;
            mol.atoms[i].y *= scale;
            mol.atoms[i].z *= scale;
        }
    }
};

function getAverageBondLength(mol) {
    if (mol.bonds.length === 0) {
        return 0;
    }
    var tot = 0;
    for (var i = 0, ii = mol.bonds.length; i < ii; i++) {
        tot += mol.bonds[i].getLength3D();
    }
    tot /= mol.bonds.length;
    return tot;
};

// Use the jQuery embedded within ChemDoodle
ChemDoodle.lib.jQuery(document).ready(function($) {
    var buttons = $('.button'),
    viewers = $('canvas'),
    width = window.innerWidth,
    height = window.innerHeight,
    sb = new ChemDoodle.informatics.StructureBuilder();

    // Start with buttons and viewers hidden
    buttons.hide();
    viewers.hide();
    var transformer = new ChemDoodle.TransformCanvas('transformer', width, height);
    var viewer = new ChemDoodle.ViewerCanvas('viewer', width, height);

    // Construct ChemDoodle Molecule from molecule data
    var mol = undefined,
        unitcell = undefined;
    if (extension === 'cdjson') {
        var parsed = ChemDoodle.readJSON(molstring);
        if (typeof parsed !== 'undefined' && typeof parsed.molecules[0] !== 'undefined') {
            mol = parsed.molecules[0];
        }
    } else if (extension === 'pdb') {
        mol = ChemDoodle.readPDB(molstring);
    } else if (extension === 'cif') {
        var parsed = ChemDoodle.readCIF(molstring);
        mol = parsed.molecule;
        unitcell = parsed.unitCell;
    } else {
        mol = ChemDoodle.readMOL(molstring);
    }
    scaleMol(mol);

    // Initialize 3D canvas
    transformer.emptyMessage = 'Molecule failed to load';
    transformer.rotate3D = true;
    transformer.rotationMultMod = 1.6;
    transformer.specs.bonds_useJMOLColors = true;
    transformer.specs.bonds_width_2D = 3;
    transformer.specs.atoms_display = false;
    transformer.specs.backgroundColor = 'black';
    transformer.specs.bonds_clearOverlaps_2D = true;
    transformer.loadMolecule(mol);

    // If no z coordinate, also initialize 2D canvas and display buttons
    var withz = mol.atoms.filter(function(a){return a.z !== 0;});
    if (withz.length === 0) {
        var mol2d = sb.copy(mol)
        new ChemDoodle.informatics.HydrogenDeducer().removeHydrogens(mol2d);
        buttons.show();
        viewer.emptyMessage = 'Molecule failed to load';
        viewer.specs.bonds_width_2D = 2;
        viewer.specs.bonds_saturationWidth_2D = .18;
        viewer.specs.bonds_hashSpacing_2D = 2.5;
        viewer.specs.atoms_font_size_2D = 12;
        viewer.specs.atoms_font_families_2D = ['Helvetica', 'Arial', 'sans-serif'];
        viewer.specs.atoms_displayTerminalCarbonLabels_2D = false;
        viewer.specs.bonds_clearOverlaps_2D = true;
        viewer.specs.bonds_useJMOLColors = true;
        viewer.specs.atoms_useJMOLColors = true;
        viewer.specs.backgroundColor = 'white';
        viewer.loadMolecule(mol2d);
    }

    // Toggle viewers when buttons are clicked
    buttons.click(function(e) {
        e.preventDefault();
        var activeViewer = $($('.button.active')[0].hash);
        var nextViewer = $(this.hash);
        activeViewer.fadeOut(200, function() { nextViewer.fadeIn(200); });
        buttons.removeClass('active');
        $(this).addClass('active');
        return false;
    });

    // Show 3D by default
    $('#threed').click();

    // Resize viewers with window
    $(window).resize(function(e) {
        viewer.resize(window.innerWidth, window.innerHeight);
        transformer.resize(window.innerWidth, window.innerHeight);
    });
});
