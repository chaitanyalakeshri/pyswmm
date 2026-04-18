"""
Convert SWMM Users Manual PDF to structured markdown files.
PDF page (1-based) = doc page + 2  (verified: doc page 14 = PDF page 16)
"""

import fitz
import os
import re
from pathlib import Path
from collections import Counter

PDF_PATH = r"C:\Chaitanya\MasaLab\012 Pyswmm\pyswmm\swmm\swmm-users-manual-version-5.2.pdf"
OUTPUT_DIR = r"C:\Chaitanya\MasaLab\012 Pyswmm\pyswmm\swmm\swmm-users-manual-version-5.2"
PAGE_OFFSET = 2  # pdf_page_1based = doc_page + PAGE_OFFSET

# ---------------------------------------------------------------------------
# TOC structure: (folder, [(section_id, section_name, start_doc_page), ...])
# end page for each section = start of next section - 1
# ---------------------------------------------------------------------------
TOC = [
    ("00_front_matter", [
        ("00_disclaimer",       "Disclaimer",       None, 4, 4),   # pdf 1-based
        ("00_abstract",         "Abstract",         None, 5, 5),
        ("00_forward",          "Forward",          None, 6, 6),
        ("00_acknowledgements", "Acknowledgements", None, 7, 7),
    ]),
    ("chapter_01_introduction", [
        ("1.1", "What_is_SWMM",                    14, None, None),
        ("1.2", "Modeling_Capabilities",            15, None, None),
        ("1.3", "Typical_Applications_of_SWMM",    16, None, None),
        ("1.4", "Installing_EPA_SWMM",              16, None, None),
        ("1.5", "Steps_in_Using_SWMM",              17, None, None),
        ("1.6", "About_This_Manual",                18, None, None),
    ]),
    ("chapter_02_quick_start_tutorial", [
        ("2.1", "Example_Study_Area",               20, None, None),
        ("2.2", "Project_Setup",                    21, None, None),
        ("2.3", "Drawing_Objects",                  24, None, None),
        ("2.4", "Setting_Object_Properties",        26, None, None),
        ("2.5", "Running_a_Simulation",             31, None, None),
        ("2.6", "Simulating_Water_Quality",         41, None, None),
        ("2.7", "Running_a_Continuous_Simulation",  46, None, None),
    ]),
    ("chapter_03_swmms_conceptual_model", [
        ("3.1", "Introduction",                     50, None, None),
        ("3.2", "Visual_Objects",                   51, None, None),
        ("3.3", "Non-Visual_Objects",               63, None, None),
        ("3.4", "Computational_Methods",            84, None, None),
    ]),
    ("chapter_04_swmms_main_window", [
        ("4.1",  "Overview",                        94, None, None),
        ("4.2",  "Main_Menu",                       95, None, None),
        ("4.3",  "Keyboard_Shortcuts",              99, None, None),
        ("4.4",  "Toolbars",                        99, None, None),
        ("4.5",  "Status_Bar",                     101, None, None),
        ("4.6",  "Study_Area_Map",                 102, None, None),
        ("4.7",  "Project_Browser",                103, None, None),
        ("4.8",  "Map_Browser",                    104, None, None),
        ("4.9",  "Property_Editor",                106, None, None),
        ("4.10", "Setting_Program_Preferences",    107, None, None),
    ]),
    ("chapter_05_working_with_projects", [
        ("5.1", "Creating_a_New_Project",           110, None, None),
        ("5.2", "Opening_an_Existing_Project",      110, None, None),
        ("5.3", "Saving_a_Project",                 111, None, None),
        ("5.4", "Setting_Project_Defaults",         111, None, None),
        ("5.5", "Measurement_Units",                113, None, None),
        ("5.6", "Link_Offset_Conventions",          114, None, None),
        ("5.7", "Calibration_Data",                 114, None, None),
        ("5.8", "Viewing_All_Project_Data",         116, None, None),
    ]),
    ("chapter_06_working_with_objects", [
        ("6.1",  "Types_of_Objects",                118, None, None),
        ("6.2",  "Adding_Objects",                  118, None, None),
        ("6.3",  "Selecting_and_Moving_Objects",    119, None, None),
        ("6.4",  "Editing_Objects",                 120, None, None),
        ("6.5",  "Converting_an_Object",            121, None, None),
        ("6.6",  "Copying_and_Pasting_Objects",     122, None, None),
        ("6.7",  "Shaping_and_Reversing_Links",     122, None, None),
        ("6.8",  "Shaping_a_Subcatchment",          123, None, None),
        ("6.9",  "Deleting_an_Object",              123, None, None),
        ("6.10", "Editing_or_Deleting_a_Group",     123, None, None),
    ]),
    ("chapter_07_working_with_the_map", [
        ("7.1",  "Viewing_Map_Layers",              126, None, None),
        ("7.2",  "Selecting_a_Map_Theme",           127, None, None),
        ("7.3",  "Setting_the_Maps_Dimensions",     127, None, None),
        ("7.4",  "Utilizing_a_Backdrop_Image",      128, None, None),
        ("7.5",  "Measuring_Distances",             132, None, None),
        ("7.6",  "Zooming_the_Map",                 133, None, None),
        ("7.7",  "Panning_the_Map",                 133, None, None),
        ("7.8",  "Viewing_at_Full_Extent",          134, None, None),
        ("7.9",  "Finding_an_Object",               134, None, None),
        ("7.10", "Submitting_a_Map_Query",          135, None, None),
        ("7.11", "Using_the_Map_Legends",           136, None, None),
        ("7.12", "Using_the_Overview_Map",          138, None, None),
        ("7.13", "Setting_Map_Display_Options",     138, None, None),
        ("7.14", "Exporting_the_Map",               143, None, None),
    ]),
    ("chapter_08_running_a_simulation", [
        ("8.1", "Setting_Simulation_Options",       145, None, None),
        ("8.2", "Setting_Reporting_Options",        153, None, None),
        ("8.3", "Selecting_Event_Periods",          155, None, None),
        ("8.4", "Starting_a_Simulation",            157, None, None),
        ("8.5", "Troubleshooting_Results",          157, None, None),
    ]),
    ("chapter_09_viewing_results", [
        ("9.1", "Viewing_a_Status_Report",          161, None, None),
        ("9.2", "Viewing_Summary_Results",          162, None, None),
        ("9.3", "Time_Series_Results",              166, None, None),
        ("9.4", "Viewing_Results_on_the_Map",       168, None, None),
        ("9.5", "Viewing_Results_with_a_Graph",     168, None, None),
        ("9.6", "Customizing_a_Graphs_Appearance",  175, None, None),
        ("9.7", "Viewing_Results_with_a_Table",     180, None, None),
        ("9.8", "Viewing_a_Statistics_Report",      183, None, None),
    ]),
    ("chapter_10_printing_and_copying", [
        ("10.1", "Selecting_a_Printer",             187, None, None),
        ("10.2", "Setting_the_Page_Format",         188, None, None),
        ("10.3", "Print_Preview",                   189, None, None),
        ("10.4", "Printing_the_Current_View",       189, None, None),
        ("10.5", "Copying_to_Clipboard_or_File",    189, None, None),
    ]),
    ("chapter_11_files_used_by_swmm", [
        ("11.1", "Project_Files",                   191, None, None),
        ("11.2", "Report_and_Output_Files",         191, None, None),
        ("11.3", "Rainfall_Files",                  192, None, None),
        ("11.4", "Climate_Files",                   193, None, None),
        ("11.5", "Calibration_Files",               193, None, None),
        ("11.6", "Time_Series_Files",               195, None, None),
        ("11.7", "Interface_Files",                 196, None, None),
    ]),
    ("chapter_12_using_add-in_tools", [
        ("12.1", "What_Are_Add-In_Tools",           201, None, None),
        ("12.2", "Configuring_Add-In_Tools",        202, None, None),
    ]),
    ("appendix_A_useful_tables", [
        ("A.1",  "Units_of_Measurement",            206, None, None),
        ("A.2",  "Soil_Characteristics",            207, None, None),
        ("A.3",  "NRCS_Hydrologic_Soil_Group",      208, None, None),
        ("A.4",  "SCS_Curve_Numbers",               209, None, None),
        ("A.5",  "Depression_Storage",              210, None, None),
        ("A.6",  "Mannings_Coeff_Overland_Flow",    211, None, None),
        ("A.7",  "Mannings_Coeff_Closed_Conduits",  212, None, None),
        ("A.8",  "Mannings_Coeff_Open_Channels",    213, None, None),
        ("A.9",  "Water_Quality_Urban_Runoff",      214, None, None),
        ("A.10", "Culvert_Code_Numbers",            215, None, None),
        ("A.11", "Culvert_Entrance_Loss_Coeff",     218, None, None),
        ("A.12", "Standard_Elliptical_Pipe_Sizes",  220, None, None),
        ("A.13", "Standard_Arch_Pipe_Sizes",        221, None, None),
    ]),
    ("appendix_B_visual_object_properties", [
        ("B.1",  "Rain_Gage_Properties",            225, None, None),
        ("B.2",  "Subcatchment_Properties",         226, None, None),
        ("B.3",  "Junction_Properties",             228, None, None),
        ("B.4",  "Outfall_Properties",              229, None, None),
        ("B.5",  "Flow_Divider_Properties",         230, None, None),
        ("B.6",  "Storage_Unit_Properties",         232, None, None),
        ("B.7",  "Conduit_Properties",              233, None, None),
        ("B.8",  "Pump_Properties",                 235, None, None),
        ("B.9",  "Orifice_Properties",              236, None, None),
        ("B.10", "Weir_Properties",                 237, None, None),
        ("B.11", "Outlet_Properties",               238, None, None),
        ("B.12", "Map_Label_Properties",            239, None, None),
    ]),
    ("appendix_C_specialized_property_editors", [
        ("C.1",  "Aquifer_Editor",                  240, None, None),
        ("C.2",  "Climatology_Editor",              243, None, None),
        ("C.3",  "Control_Rules_Editor",            253, None, None),
        ("C.4",  "Cross-Section_Editor",            260, None, None),
        ("C.5",  "Curve_Editor",                    262, None, None),
        ("C.6",  "Groundwater_Flow_Editor",         264, None, None),
        ("C.7",  "Groundwater_Equation_Editor",     268, None, None),
        ("C.8",  "Infiltration_Editor",             269, None, None),
        ("C.9",  "Inflows_Editor",                  272, None, None),
        ("C.10", "Initial_Buildup_Editor",          276, None, None),
        ("C.11", "Inlet_Structure_Editor",          277, None, None),
        ("C.12", "Inlet_Usage_Editor",              281, None, None),
        ("C.13", "Land_Use_Assignment_Editor",      283, None, None),
        ("C.14", "Land_Use_Editor",                 284, None, None),
        ("C.15", "LID_Control_Editor",              289, None, None),
        ("C.16", "LID_Group_Editor",                297, None, None),
        ("C.17", "LID_Usage_Editor",                298, None, None),
        ("C.18", "Pollutant_Editor",                301, None, None),
        ("C.19", "Snow_Pack_Editor",                303, None, None),
        ("C.20", "Storage_Shape_Editor",            307, None, None),
        ("C.21", "Street_Section_Editor",           310, None, None),
        ("C.22", "Time_Pattern_Editor",             313, None, None),
        ("C.23", "Time_Series_Editor",              315, None, None),
        ("C.24", "Title_Notes_Editor",              317, None, None),
        ("C.25", "Transect_Editor",                 318, None, None),
        ("C.26", "Treatment_Editor",                320, None, None),
        ("C.27", "Unit_Hydrograph_Editor",          322, None, None),
    ]),
    ("appendix_D_command_line_swmm", [
        ("D.1", "General_Instructions",             324, None, None),
        ("D.2", "Input_File_Format",                324, None, None),
        ("D.3", "Map_Data_Section",                 405, None, None),
    ]),
    ("appendix_E_error_and_warning_messages", [
        ("E",   "Error_and_Warning_Messages",       411, None, None),
    ]),
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def doc_to_pdf_idx(doc_page):
    """0-based PDF page index from 1-based document page number."""
    return doc_page + PAGE_OFFSET - 1


def slugify(text):
    return re.sub(r'[^a-zA-Z0-9_\-.]', '_', text).strip('_')


BULLET_CHARS = set('•·▪▸▹◦‣⁃\uf0a7\uf0b7\uf0d8')


def flags_to_md(text, flags):
    bold   = bool(flags & 2**4)
    italic = bool(flags & 2**1)
    text = text.replace('**', '').replace('*', '')
    if bold and italic:
        return f"***{text}***"
    if bold:
        return f"**{text}**"
    if italic:
        return f"*{text}*"
    return text


def is_page_number_block(block_text):
    """True if the block is just a lone page number (Arabic or Roman)."""
    t = block_text.strip()
    if re.fullmatch(r'\d{1,4}', t):
        return True
    if re.fullmatch(r'[ivxlcdmIVXLCDM]{1,6}', t):
        return True
    return False


def analyse_font_sizes(doc, sample_pages=50):
    """Return a sorted list of font sizes seen in body text to calibrate heading detection."""
    sizes = Counter()
    step = max(1, doc.page_count // sample_pages)
    for i in range(0, doc.page_count, step):
        page = doc[i]
        for block in page.get_text("dict")["blocks"]:
            if block["type"] != 0:
                continue
            for line in block["lines"]:
                for span in line["spans"]:
                    sizes[round(span["size"], 1)] += len(span["text"].strip())
    # Body text = most common size
    if not sizes:
        return 10.0
    body_size = sizes.most_common(1)[0][0]
    return body_size


def block_to_markdown(block, body_size, images_dir, page_images, img_counter):
    """Convert a single page block (dict form) to a markdown string segment."""
    if block["type"] == 1:
        # Image block – save and reference
        img_idx = img_counter[0]
        img_counter[0] += 1
        img_name = f"img_{img_idx:04d}.png"
        img_path = os.path.join(images_dir, img_name)
        # Already saved via page.get_images() earlier; just emit reference
        return f"\n![Figure]({os.path.join('images', img_name).replace(chr(92), '/')})\n"

    lines_md = []
    for line in block["lines"]:
        spans = line["spans"]
        if not spans:
            continue
        # Build line text
        line_text = ""
        for span in spans:
            t = span["text"]
            if not t.strip():
                line_text += t
                continue
            line_text += flags_to_md(t, span["flags"])
        line_text = line_text.strip()
        if not line_text:
            continue
        lines_md.append(line_text)

    if not lines_md:
        return ""

    full_text = " ".join(lines_md)

    # Detect heading level from font size of first span in first line
    try:
        first_size = round(block["lines"][0]["spans"][0]["size"], 1)
    except (IndexError, KeyError):
        first_size = body_size

    # Heuristic heading thresholds
    if first_size >= body_size * 1.55:
        prefix = "# "
    elif first_size >= body_size * 1.30:
        prefix = "## "
    elif first_size >= body_size * 1.12:
        prefix = "### "
    else:
        prefix = ""

    if prefix:
        return f"\n{prefix}{full_text}\n"

    # Detect bullet list
    first_char = full_text[0] if full_text else ""
    if first_char in BULLET_CHARS:
        return f"\n- {full_text[1:].strip()}"

    # Detect numbered list (e.g. "1. " or "1. ")
    if re.match(r'^\d+[\.\)]\s', full_text):
        num, rest = re.split(r'[\.\)]\s', full_text, maxsplit=1)
        return f"\n{num}. {rest}"

    return f"\n{full_text}"


def save_page_images(page, images_dir, base_counter):
    """Extract and save all images from a page; return count saved."""
    saved = 0
    doc = page.parent
    for img_info in page.get_images(full=True):
        xref = img_info[0]
        try:
            base_image = doc.extract_image(xref)
            ext = base_image["ext"]
            img_data = base_image["image"]
            img_name = f"img_{base_counter + saved:04d}.{ext}"
            img_path = os.path.join(images_dir, img_name)
            if not os.path.exists(img_path):
                with open(img_path, "wb") as f:
                    f.write(img_data)
            saved += 1
        except Exception:
            pass
    return saved


def pages_to_markdown(doc, start_idx, end_idx, images_dir, body_size, global_img_counter):
    """Extract markdown text + inline image refs from PDF pages [start_idx..end_idx] (0-based, inclusive)."""
    os.makedirs(images_dir, exist_ok=True)
    md_parts = []
    prev_page_num_text = None

    for pidx in range(start_idx, end_idx + 1):
        if pidx >= doc.page_count:
            break
        page = doc[pidx]

        # Save images first
        saved = save_page_images(page, images_dir, global_img_counter[0])
        img_counter_for_page = [global_img_counter[0]]
        global_img_counter[0] += saved

        page_dict = page.get_text("dict", sort=True)
        blocks = page_dict["blocks"]

        page_md = []
        for block in blocks:
            if block["type"] == 0:
                raw = " ".join(
                    span["text"]
                    for line in block["lines"]
                    for span in line["spans"]
                ).strip()
                if is_page_number_block(raw):
                    continue
            result = block_to_markdown(block, body_size, images_dir, None, img_counter_for_page)
            if result:
                page_md.append(result)

        md_parts.append("\n".join(page_md))

    return "\n\n".join(md_parts)


# ---------------------------------------------------------------------------
# Compute page ranges for every section
# ---------------------------------------------------------------------------

def resolve_ranges(toc):
    """
    Fill in (start_pdf_idx, end_pdf_idx) for each section.
    Sections with doc_page use PAGE_OFFSET; front-matter sections have direct pdf_page.
    """
    resolved = []

    # Flatten all sections with their computed start pdf_idx
    all_sections = []
    for folder, sections in toc:
        for sec in sections:
            sec_id, sec_name, doc_page, pdf_page_direct, _ = sec
            if doc_page is not None:
                start_idx = doc_to_pdf_idx(doc_page)
            else:
                start_idx = pdf_page_direct - 1  # convert 1-based to 0-based
            all_sections.append((folder, sec_id, sec_name, start_idx))

    # Determine end_idx for each section
    for i, (folder, sec_id, sec_name, start_idx) in enumerate(all_sections):
        if i + 1 < len(all_sections):
            next_start = all_sections[i + 1][3]
            # If next section starts on same page, end = start (same page, content will overlap slightly)
            end_idx = max(start_idx, next_start - 1)
        else:
            end_idx = 423  # last PDF page index (424 pages, 0-based = 423)
        resolved.append((folder, sec_id, sec_name, start_idx, end_idx))

    return resolved


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    doc = fitz.open(PDF_PATH)
    print(f"Opened PDF: {doc.page_count} pages")

    print("Analysing font sizes...")
    body_size = analyse_font_sizes(doc)
    print(f"  Body text size: {body_size}pt")

    sections = resolve_ranges(TOC)
    global_img_counter = [0]

    for folder, sec_id, sec_name, start_idx, end_idx in sections:
        folder_path = os.path.join(OUTPUT_DIR, folder)
        os.makedirs(folder_path, exist_ok=True)
        images_dir = os.path.join(folder_path, "images")

        filename = f"{sec_id}_{sec_name}.md"
        filepath = os.path.join(folder_path, filename)

        print(f"  [{sec_id}] PDF pages {start_idx+1}-{end_idx+1} -> {folder}/{filename}")

        md = pages_to_markdown(doc, start_idx, end_idx, images_dir, body_size, global_img_counter)

        # Write markdown file
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(md)

    doc.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
