// Scale molecule to a consistent size on canvas
function getScaledMol(mol, length) {
    var sb = new ChemDoodle.informatics.StructureBuilder(),
    avBondLength = getAverageBondLength(mol),
    scaledMol = sb.copy(mol);
    if (avBondLength !== 0) {
        var scale = length / avBondLength;
        for (var i = 0, ii = scaledMol.atoms.length; i < ii; i++) {
            scaledMol.atoms[i].x *= scale;
            scaledMol.atoms[i].y *= scale;
            scaledMol.atoms[i].z *= scale;
        }
    }
    return scaledMol;
};

// Get the average length of all bonds in a molecule
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

// Initialize 3D canvas viewer
function init3dView() {
    var viewer = new ChemDoodle.TransformCanvas('view3d', window.innerWidth, window.innerHeight);
    viewer.emptyMessage = 'Molecule failed to load';
    viewer.rotate3D = true;
    viewer.rotationMultMod = 1.6;
    viewer.specs.bonds_useJMOLColors = true;
    viewer.specs.bonds_width_2D = 3;
    viewer.specs.atoms_display = false;
    viewer.specs.backgroundColor = 'black';
    viewer.specs.bonds_clearOverlaps_2D = true;
    return viewer;
}

// Initialize 2D canvas viewer
function init2dView() {
    var viewer = new ChemDoodle.TransformCanvas('view2d', window.innerWidth, window.innerHeight);
    viewer.emptyMessage = 'Molecule failed to load';
    viewer.specs.bonds_width_2D = 2;
    viewer.specs.bonds_saturationWidth_2D = .18;
    viewer.specs.bonds_hashSpacing_2D = 2.5;
    viewer.specs.bonds_atomLabelBuffer_2D = 3;
    viewer.specs.atoms_font_size_2D = 15;
    viewer.specs.atoms_font_families_2D = ['Helvetica', 'Arial', 'sans-serif'];
    viewer.specs.atoms_displayTerminalCarbonLabels_2D = false;
    viewer.specs.bonds_clearOverlaps_2D = true;
    viewer.specs.bonds_useJMOLColors = true;
    viewer.specs.atoms_useJMOLColors = true;
    viewer.specs.backgroundColor = 'white';
    return viewer;
}

ChemDoodle.lib.jQuery(document).ready(function($) {
    var buttons = $('.button').hide(),
        viewers = $('canvas').hide(),
        view3d = init3dView(),
        view2d = init2dView(),
        mol = undefined,
        unitcell = undefined;

    // Construct ChemDoodle Molecule from molecule data
    if (extension === 'cdjson') {
        var parsed = ChemDoodle.readJSON(molstring);
        if (typeof parsed !== 'undefined' && typeof parsed.molecules[0] !== 'undefined') {
            mol = parsed.molecules[0];
        }
    } else if (extension === 'pdb') {
        mol = ChemDoodle.readPDB(molstring, 1);
    } else if (extension === 'cif') {
        var parsed = ChemDoodle.readCIF(molstring);
        mol = parsed.molecule;
        unitcell = parsed.unitCell;
    } else {
        mol = ChemDoodle.readMOL(molstring);
    }

    // Load mol into 3D viewer
    var mol3d = getScaledMol(mol, 30);
    view3d.loadMolecule(mol3d);

    // If no z coordinate, also load mol into 2D viewer and display buttons
    var withz = mol.atoms.filter(function(a){return a.z !== 0;});
    if (withz.length === 0) {
        var mol2d = getScaledMol(mol, 35);
        new ChemDoodle.informatics.HydrogenDeducer().removeHydrogens(mol2d);
        view2d.loadMolecule(mol2d);
        buttons.show();
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
    $('#button3d').click();

    // Resize viewers with window
    $(window).resize(function(e) {
        view2d.resize(window.innerWidth, window.innerHeight);
        view3d.resize(window.innerWidth, window.innerHeight);
    });
});
