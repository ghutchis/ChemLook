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
    if (cdjson !== '') {
        // If available, use the ChemDoodle JSON produced by Open Babel
        var mol = ChemDoodle.readJSON(cdjson);
        // TODO: Support previewing multiple molecules (for now we just take the first)
        if (typeof(mol) !== 'undefined') {
            mol = mol.molecules[0];
        }
    }

    // If no ChemDoodle JSON, use the raw file contents instead with ChemDoodle reader
    if (typeof(mol) === 'undefined' && raw !== '') {
        if (extension === 'pdb') {
            var mol = ChemDoodle.readPDB(raw);
        } else if (extension === 'cif') {
            var mol = ChemDoodle.readCIF(raw);
        } else if (extension === 'xyz') {
            var mol = ChemDoodle.readXYZ(raw);
        } else {
            var mol = ChemDoodle.readMOL(raw);
        }
    }
    scaleMol(mol);

    // Read unit cell (work in progress)
    if (raw && extension === 'cif') {
        // Get the unit cell vectors by reading the raw file contents
        if (mol.hasOwnProperty('unitCellVectors')) {
            var uv = mol.unitCellVectors;
        } else {
            var cifmol = ChemDoodle.readCIF(raw),
            uv = cifmol.unitCellVectors;
        }
        // TODO: Somehow display unit cell on transformer canvas
        // The following creates box from fake atoms and bonds - almost there but doesn't quite work right
        //            var f1 = new ChemDoodle.structures.Atom('F', uv.o[0], uv.o[1], uv.o[2]);
        //            var f2 = new ChemDoodle.structures.Atom('F', uv.x[0], uv.x[1], uv.x[2]);
        //            var f3 = new ChemDoodle.structures.Atom('F', uv.xy[0], uv.xy[1], uv.xy[2]);
        //            var f4 = new ChemDoodle.structures.Atom('F', uv.y[0], uv.y[1], uv.y[2]);
        //            var f5 = new ChemDoodle.structures.Atom('F', uv.z[0], uv.z[1], uv.z[2]);
        //            var f6 = new ChemDoodle.structures.Atom('F', uv.xz[0], uv.xz[1], uv.xz[2]);
        //            var f7 = new ChemDoodle.structures.Atom('F', uv.xyz[0], uv.xyz[1], uv.xyz[2]);
        //            var f8 = new ChemDoodle.structures.Atom('F', uv.yz[0], uv.yz[1], uv.yz[2]);
        //            var b1 = new ChemDoodle.structures.Bond(f1, f2, 1);
        //            var b2 = new ChemDoodle.structures.Bond(f2, f3, 1);
        //            var b3 = new ChemDoodle.structures.Bond(f3, f4, 1);
        //            var b4 = new ChemDoodle.structures.Bond(f4, f1, 1);
        //            var b5 = new ChemDoodle.structures.Bond(f5, f6, 1);
        //            var b6 = new ChemDoodle.structures.Bond(f6, f7, 1);
        //            var b7 = new ChemDoodle.structures.Bond(f7, f8, 1);
        //            var b8 = new ChemDoodle.structures.Bond(f8, f5, 1);
        //            var b9 = new ChemDoodle.structures.Bond(f1, f5, 1);
        //            var b10 = new ChemDoodle.structures.Bond(f2, f6, 1);
        //            var b11 = new ChemDoodle.structures.Bond(f3, f7, 1);
        //            var b12 = new ChemDoodle.structures.Bond(f4, f8, 1);
        //            mol.atoms.push(f1);
        //            mol.atoms.push(f2);
        //            mol.atoms.push(f3);
        //            mol.atoms.push(f4);
        //            mol.atoms.push(f5);
        //            mol.atoms.push(f6);
        //            mol.atoms.push(f7);
        //            mol.atoms.push(f8);
        //            mol.bonds.push(b1);
        //            mol.bonds.push(b2);
        //            mol.bonds.push(b3);
        //            mol.bonds.push(b4);
        //            mol.bonds.push(b5);
        //            mol.bonds.push(b6);
        //            mol.bonds.push(b7);
        //            mol.bonds.push(b8);
        //            mol.bonds.push(b9);
        //            mol.bonds.push(b10);
        //            mol.bonds.push(b11);
        //            mol.bonds.push(b12);
    }

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
