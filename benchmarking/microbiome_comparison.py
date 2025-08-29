#!/usr/bin/env python3
"""
Microbiome Composition Comparison Script

Compare expected vs measured composition of ZymoResearch mock microbiome sample
Creates side-by-side stacked bar plots at species and phylum levels.

Usage: python microbiome_comparison.py
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

def read_expected_data(file_path):
    """Read expected composition data from CSV file."""
    try:
        df = pd.read_csv(file_path)
        print(f"Expected data columns: {df.columns.tolist()}")
        print(f"Expected data shape: {df.shape}")
        return df
    except Exception as e:
        print(f"Error reading expected data: {e}")
        return None

def read_measured_data(file_path):
    """Read measured composition data from CSV file, skipping header."""
    try:
        df = pd.read_csv(file_path, skiprows=1)
        print(f"Measured data columns: {df.columns.tolist()}")
        print(f"Measured data shape: {df.shape}")
        return df
    except Exception as e:
        print(f"Error reading measured data: {e}")
        return None

def get_species_phylum_mapping():
    """
    Define the phylum mapping for ZymoResearch mock community species.
    Based on standard bacterial taxonomy.
    """
    return {
        'Pseudomonas aeruginosa': 'Proteobacteria',
        'Escherichia coli': 'Proteobacteria', 
        'Salmonella enterica': 'Proteobacteria',
        'Lactobacillus fermentum': 'Firmicutes',
        'Enterococcus faecalis': 'Firmicutes',
        'Staphylococcus aureus': 'Firmicutes',
        'Listeria monocytogenes': 'Firmicutes',
        'Bacillus subtilis': 'Firmicutes',
        'Saccharomyces cerevisiae': 'Ascomycota',
        'Cryptococcus neoformans': 'Basidiomycota'
    }

def normalize_species_names(name):
    """Normalize species names for consistent matching."""
    # Remove extra whitespace and standardize format
    name = name.strip()
    
    # Handle common variations in naming
    name_mappings = {
        'E. coli': 'Escherichia coli',
        'P. aeruginosa': 'Pseudomonas aeruginosa',
        'S. enterica': 'Salmonella enterica',
        'L. fermentum': 'Lactobacillus fermentum',
        'E. faecalis': 'Enterococcus faecalis',
        'S. aureus': 'Staphylococcus aureus',
        'L. monocytogenes': 'Listeria monocytogenes',
        'B. subtilis': 'Bacillus subtilis',
        'S. cerevisiae': 'Saccharomyces cerevisiae',
        'C. neoformans': 'Cryptococcus neoformans'
    }
    
    return name_mappings.get(name, name)

def process_species_data(expected_df, measured_df):
    """Process and align species-level data."""
    species_phylum_map = get_species_phylum_mapping()
    
    # Process expected data
    expected_species = []
    expected_abundance = []
    
    # Assuming expected data has columns like 'Species' and 'Abundance' or similar
    # We'll need to adapt based on actual column names
    for col in expected_df.columns:
        if 'species' in col.lower() or 'organism' in col.lower():
            species_col = col
        elif 'abundance' in col.lower() or 'percent' in col.lower() or '%' in col:
            abundance_col = col
    
    for _, row in expected_df.iterrows():
        species = normalize_species_names(str(row[species_col]))
        abundance = float(row[abundance_col])
        expected_species.append(species)
        expected_abundance.append(abundance)
    
    # Process measured data
    measured_species = []
    measured_abundance = []
    
    # Find relevant columns in measured data
    abundance_col = None
    species_col = None
    
    for col in measured_df.columns:
        if 'abundance [%]' in col.lower() or 'abundance' in col.lower():
            abundance_col = col
        elif 'species' in col.lower() or 'organism' in col.lower() or 'name' in col.lower():
            species_col = col
    
    if abundance_col is None or species_col is None:
        print("Could not find required columns in measured data")
        print("Available columns:", measured_df.columns.tolist())
        return None, None
    
    for _, row in measured_df.iterrows():
        species = normalize_species_names(str(row[species_col]))
        try:
            abundance = float(row[abundance_col])
            measured_species.append(species)
            measured_abundance.append(abundance)
        except (ValueError, TypeError):
            continue
    
    # Create aligned dataframes
    all_species = list(set(expected_species + measured_species))
    
    expected_dict = dict(zip(expected_species, expected_abundance))
    measured_dict = dict(zip(measured_species, measured_abundance))
    
    aligned_data = []
    for species in all_species:
        expected_val = expected_dict.get(species, 0)
        measured_val = measured_dict.get(species, 0)
        phylum = species_phylum_map.get(species, 'Unknown')
        
        aligned_data.append({
            'Species': species,
            'Expected': expected_val,
            'Measured': measured_val,
            'Phylum': phylum
        })
    
    return pd.DataFrame(aligned_data)

def aggregate_by_phylum(species_df):
    """Aggregate species data by phylum."""
    phylum_data = species_df.groupby('Phylum')[['Expected', 'Measured']].sum().reset_index()
    return phylum_data

def create_stacked_bar_plot(data, level, output_file):
    """Create side-by-side stacked bar plots."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 8))
    
    # Color palette - use consistent colors for each taxon
    if level == 'Species':
        taxa = data['Species'].tolist()
    else:
        taxa = data['Phylum'].tolist()
    
    colors = plt.cm.Set3(np.linspace(0, 1, len(taxa)))
    color_map = dict(zip(taxa, colors))
    
    # Expected composition (left plot)
    bottom_expected = 0
    for i, row in data.iterrows():
        taxon = row[level]
        abundance = row['Expected']
        ax1.bar('Expected', abundance, bottom=bottom_expected, 
                color=color_map[taxon], label=taxon, alpha=0.8)
        
        # Add percentage labels for significant components
        if abundance > 2:  # Only label if > 2%
            ax1.text(0, bottom_expected + abundance/2, f'{abundance:.1f}%', 
                    ha='center', va='center', fontweight='bold', fontsize=10)
        
        bottom_expected += abundance
    
    # Measured composition (right plot)
    bottom_measured = 0
    for i, row in data.iterrows():
        taxon = row[level]
        abundance = row['Measured']
        ax2.bar('Measured', abundance, bottom=bottom_measured, 
                color=color_map[taxon], alpha=0.8)
        
        # Add percentage labels for significant components
        if abundance > 2:  # Only label if > 2%
            ax2.text(0, bottom_measured + abundance/2, f'{abundance:.1f}%', 
                    ha='center', va='center', fontweight='bold', fontsize=10)
        
        bottom_measured += abundance
    
    # Formatting
    ax1.set_title(f'Expected {level} Composition', fontsize=14, fontweight='bold')
    ax2.set_title(f'Measured {level} Composition', fontsize=14, fontweight='bold')
    
    ax1.set_ylabel('Relative Abundance (%)', fontsize=12)
    ax2.set_ylabel('Relative Abundance (%)', fontsize=12)
    
    ax1.set_ylim(0, 100)
    ax2.set_ylim(0, 100)
    
    # Legend
    handles, labels = ax1.get_legend_handles_labels()
    fig.legend(handles, labels, loc='center right', bbox_to_anchor=(1.15, 0.5), 
              fontsize=10, title=level)
    
    plt.suptitle(f'ZymoResearch Mock Community - {level} Level Comparison', 
                 fontsize=16, fontweight='bold')
    plt.tight_layout()
    plt.subplots_adjust(right=0.85)
    
    # Save plot
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Saved {level} level plot to: {output_file}")
    
    plt.show()

def main():
    """Main function to run the analysis."""
    print("ZymoResearch Mock Community Composition Analysis")
    print("=" * 50)
    
    # File paths
    expected_file = "ZymoD6322_expected_profile.csv"
    measured_file = "ZymoD6322_3296B_classification_rates.csv"
    
    # Check if files exist
    if not Path(expected_file).exists():
        print(f"Error: {expected_file} not found")
        return
    
    if not Path(measured_file).exists():
        print(f"Error: {measured_file} not found")
        return
    
    # Read data
    print("Reading data files...")
    expected_df = read_expected_data(expected_file)
    measured_df = read_measured_data(measured_file)
    
    if expected_df is None or measured_df is None:
        print("Error reading data files")
        return
    
    # Process species-level data
    print("\nProcessing species-level data...")
    species_data = process_species_data(expected_df, measured_df)
    
    if species_data is None:
        print("Error processing species data")
        return
    
    print("\nSpecies-level data:")
    print(species_data)
    
    # Aggregate to phylum level
    print("\nAggregating to phylum level...")
    phylum_data = aggregate_by_phylum(species_data)
    print("\nPhylum-level data:")
    print(phylum_data)
    
    # Create plots
    print("\nCreating species-level comparison plot...")
    create_stacked_bar_plot(species_data, 'Species', 'zymo_species_comparison.png')
    
    print("\nCreating phylum-level comparison plot...")
    create_stacked_bar_plot(phylum_data, 'Phylum', 'zymo_phylum_comparison.png')
    
    # Summary statistics
    print("\n" + "=" * 50)
    print("SUMMARY STATISTICS")
    print("=" * 50)
    
    print("\nSpecies-level comparison:")
    for _, row in species_data.iterrows():
        species = row['Species']
        expected = row['Expected']
        measured = row['Measured']
        diff = measured - expected
        print(f"{species:25} Expected: {expected:5.1f}%  Measured: {measured:5.1f}%  Diff: {diff:+5.1f}%")
    
    print("\nPhylum-level comparison:")
    for _, row in phylum_data.iterrows():
        phylum = row['Phylum']
        expected = row['Expected']
        measured = row['Measured']
        diff = measured - expected
        print(f"{phylum:15} Expected: {expected:5.1f}%  Measured: {measured:5.1f}%  Diff: {diff:+5.1f}%")

if __name__ == "__main__":
    main()
