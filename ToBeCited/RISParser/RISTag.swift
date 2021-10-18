//
//  RISTag.swift
//  
//
//  Created by Jae Seung Lee on 10/17/21.
//

import Foundation

public enum RISTag: String {
    case TY // Type of reference (must be the first tag)
    case A1 // Primary Authors (each author on its own line preceded by the A1 tag)
    case A2 // Secondary Authors (each author on its own line preceded by the A2 tag)
    case A3 // Tertiary Authors (each author on its own line preceded by the A3 tag)
    case A4 // Subsidiary Authors (each author on its own line preceded by the A4 tag)
    case AB // Abstract
    case AD // Author Address
    case AN // Accession Number
    case AU // Author (each author on its own line preceded by the AU tag)
    case AV // Location in Archives
    case BT // This field maps to T2 for all reference types except for Whole Book and Unpublished Work references. It can contain alphanumeric characters. There is no practical limit to the length of this field.
    case C1 // Custom 1
    case C2 // Custom 2
    case C3 // Custom 3
    case C4 // Custom 4
    case C5 // Custom 5
    case C6 // Custom 6
    case C7 // Custom 7
    case C8 // Custom 8
    case CA // Caption
    case CN // Call Number
    case CP // This field can contain alphanumeric characters. There is no practical limit to the length of this field.
    case CT // Title of unpublished reference
    case CY // Place Published
    case DA // Date
    case DB // Name of Database
    case DO // DOI
    case DP // Database Provider
    case ED // Editor
    case EP // End Page
    case ET // Edition
    case ID // Reference ID
    case IS // Issue number
    case J1 // Periodical name: user abbreviation 1. This is an alphanumeric field of up to 255 characters.
    case J2 // Alternate Title (this field is used for the abbreviated title of a book or journal name, the latter mapped to T2)
    case JA // Periodical name: standard abbreviation. This is the periodical in which the article was (or is to be, in the case of in-press references) published. This is an alphanumeric field of up to 255 characters.
    case JF // Journal/Periodical name: full format. This is an alphanumeric field of up to 255 characters.
    case JO // Journal/Periodical name: full format. This is an alphanumeric field of up to 255 characters.
    case KW // Keywords (keywords should be entered each on its own line preceded by the tag)
    case L1 // Link to PDF. There is no practical limit to the length of this field. URL addresses can be entered individually, one per tag or multiple addresses can be entered on one line using a semi-colon as a separator.
    case L2 // Link to Full-text. There is no practical limit to the length of this field. URL addresses can be entered individually, one per tag or multiple addresses can be entered on one line using a semi-colon as a separator.
    case L3 // Related Records. There is no practical limit to the length of this field.
    case L4 // Image(s). There is no practical limit to the length of this field.
    case LA // Language
    case LB // Label
    case LK // Website Link
    case M1 // Number
    case M2 // Miscellaneous 2. This is an alphanumeric field and there is no practical limit to the length of this field.
    case M3 // Type of Work
    case N1 // Notes
    case N2 // Abstract. This is a free text field and can contain alphanumeric characters. There is no practical length limit to this field.
    case NV // Number of Volumes
    case OP // Original Publication
    case PB // Publisher
    case PP // Publishing Place
    case PY // Publication year (YYYY)
    case RI // Reviewed Item
    case RN // Research Notes
    case RP // Reprint Edition
    case SE // Section
    case SN // ISBN/ISSN
    case SP // Start Page
    case ST // Short Title
    case T1 // Primary Title
    case T2 // Secondary Title (journal title, if applicable)
    case T3 // Tertiary Title
    case TA // Translated Author
    case TI // Title
    case TT // Translated Title
    case U1 // User definable 1. This is an alphanumeric field and there is no practical limit to the length of this field.
    case U2 // User definable 2. This is an alphanumeric field and there is no practical limit to the length of this field.
    case U3 // User definable 3. This is an alphanumeric field and there is no practical limit to the length of this field.
    case U4 // User definable 4. This is an alphanumeric field and there is no practical limit to the length of this field.
    case U5 // User definable 5. This is an alphanumeric field and there is no practical limit to the length of this field.
    case UR // URL
    case VL // Volume number
    case VO // Published Standard number
    case Y1 // Primary Date
    case Y2 // Access Date
    case ER // End of Reference (must be empty and the last tag)
}
