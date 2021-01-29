/*
 * Copyright © 2015  Mozilla Foundation.
 * Copyright © 2015  Google, Inc.
 *
 *  This is part of HarfBuzz, a text shaping library.
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and its documentation for any purpose, provided that the
 * above copyright notice and the following two paragraphs appear in
 * all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF THE COPYRIGHT HOLDER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * THE COPYRIGHT HOLDER SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDER HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Mozilla Author(s): Jonathan Kew
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_OT_SHAPE_COMPLEX_USE_MACHINE_HH
#define HB_OT_SHAPE_COMPLEX_USE_MACHINE_HH

#include "hb.hh"

%%{
  machine use_syllable_machine;
  alphtype unsigned char;
  write exports;
  write data;
}%%

%%{

export O	= 0; # OTHER

export B	= 1; # BASE
export N	= 4; # BASE_NUM
export GB	= 5; # BASE_OTHER
export SUB	= 11; # CONS_SUB
export H	= 12; # HALANT

export HN	= 13; # HALANT_NUM
export ZWNJ	= 14; # Zero width non-joiner
export R	= 18; # REPHA
export S	= 19; # SYM
export CS	= 43; # CONS_WITH_STACKER
export HVM	= 44; # HALANT_OR_VOWEL_MODIFIER
export Sk	= 48; # SAKOT
export G	= 49; # HIEROGLYPH
export J	= 50; # HIEROGLYPH_JOINER
export SB	= 51; # HIEROGLYPH_SEGMENT_BEGIN
export SE	= 52; # HIEROGLYPH_SEGMENT_END

export FAbv	= 24; # CONS_FINAL_ABOVE
export FBlw	= 25; # CONS_FINAL_BELOW
export FPst	= 26; # CONS_FINAL_POST
export MAbv	= 27; # CONS_MED_ABOVE
export MBlw	= 28; # CONS_MED_BELOW
export MPst	= 29; # CONS_MED_POST
export MPre	= 30; # CONS_MED_PRE
export CMAbv	= 31; # CONS_MOD_ABOVE
export CMBlw	= 32; # CONS_MOD_BELOW
export VAbv	= 33; # VOWEL_ABOVE / VOWEL_ABOVE_BELOW / VOWEL_ABOVE_BELOW_POST / VOWEL_ABOVE_POST
export VBlw	= 34; # VOWEL_BELOW / VOWEL_BELOW_POST
export VPst	= 35; # VOWEL_POST	UIPC = Right
export VPre	= 22; # VOWEL_PRE / VOWEL_PRE_ABOVE / VOWEL_PRE_ABOVE_POST / VOWEL_PRE_POST
export VMAbv	= 37; # VOWEL_MOD_ABOVE
export VMBlw	= 38; # VOWEL_MOD_BELOW
export VMPst	= 39; # VOWEL_MOD_POST
export VMPre	= 23; # VOWEL_MOD_PRE
export SMAbv	= 41; # SYM_MOD_ABOVE
export SMBlw	= 42; # SYM_MOD_BELOW
export FMAbv	= 45; # CONS_FINAL_MOD	UIPC = Top
export FMBlw	= 46; # CONS_FINAL_MOD	UIPC = Bottom
export FMPst	= 47; # CONS_FINAL_MOD	UIPC = Not_Applicable

h = H | HVM | Sk;

consonant_modifiers = CMAbv* CMBlw* ((h B | SUB) CMAbv? CMBlw*)*;
medial_consonants = MPre? MAbv? MBlw? MPst?;
dependent_vowels = VPre* VAbv* VBlw* VPst*;
vowel_modifiers = HVM? VMPre* VMAbv* VMBlw* VMPst*;
final_consonants = FAbv* FBlw* FPst*;
final_modifiers = FMAbv* FMBlw* | FMPst?;

complex_syllable_start = (R | CS)? (B | GB);
complex_syllable_middle =
	consonant_modifiers
	medial_consonants
	dependent_vowels
	vowel_modifiers
	(Sk B)*
;
complex_syllable_tail =
	complex_syllable_middle
	final_consonants
	final_modifiers
;
number_joiner_terminated_cluster_tail = (HN N)* HN;
numeral_cluster_tail = (HN N)+;
symbol_cluster_tail = SMAbv+ SMBlw* | SMBlw+;

virama_terminated_cluster =
	complex_syllable_start
	consonant_modifiers
	h
;
sakot_terminated_cluster =
	complex_syllable_start
	complex_syllable_middle
	Sk
;
standard_cluster =
	complex_syllable_start
	complex_syllable_tail
;
broken_cluster =
	R?
	(complex_syllable_tail | number_joiner_terminated_cluster_tail | numeral_cluster_tail | symbol_cluster_tail)
;

number_joiner_terminated_cluster = N number_joiner_terminated_cluster_tail;
numeral_cluster = N numeral_cluster_tail?;
symbol_cluster = (S | GB) symbol_cluster_tail?;
hieroglyph_cluster = SB+ | SB* G SE* (J SE* (G SE*)?)*;
independent_cluster = O;
other = any;

main := |*
	independent_cluster			=> { found_syllable (independent_cluster); };
	virama_terminated_cluster		=> { found_syllable (virama_terminated_cluster); };
	sakot_terminated_cluster		=> { found_syllable (sakot_terminated_cluster); };
	standard_cluster			=> { found_syllable (standard_cluster); };
	number_joiner_terminated_cluster	=> { found_syllable (number_joiner_terminated_cluster); };
	numeral_cluster				=> { found_syllable (numeral_cluster); };
	symbol_cluster				=> { found_syllable (symbol_cluster); };
	hieroglyph_cluster			=> { found_syllable (hieroglyph_cluster); };
	broken_cluster				=> { found_syllable (broken_cluster); };
	other					=> { found_syllable (non_cluster); };
*|;


}%%

#define found_syllable(syllable_type) \
  HB_STMT_START { \
    if (0) fprintf (stderr, "syllable %d..%d %s\n", (*ts).second.first, (*te).second.first, #syllable_type); \
    for (unsigned i = (*ts).second.first; i < (*te).second.first; ++i) \
      info[i].syllable() = (syllable_serial << 4) | use_##syllable_type; \
    syllable_serial++; \
    if (unlikely (syllable_serial == 16)) syllable_serial = 1; \
  } HB_STMT_END

static bool
not_standard_default_ignorable (const hb_glyph_info_t &i)
{ return !(i.use_category() == USE_O && _hb_glyph_info_is_default_ignorable (&i)); }

static void
find_syllables_use (hb_buffer_t *buffer)
{
  hb_glyph_info_t *info = buffer->info;
  auto p =
    + hb_iter (info, buffer->len)
    | hb_enumerate
    | hb_filter ([] (const hb_glyph_info_t &i) { return not_standard_default_ignorable (i); },
		 hb_second)
    | hb_filter ([&] (const hb_pair_t<unsigned, const hb_glyph_info_t &> p)
		 {
		   if (p.second.use_category() == USE_ZWNJ)
		     for (unsigned i = p.first + 1; i < buffer->len; ++i)
		       if (not_standard_default_ignorable (info[i]))
			 return !_hb_glyph_info_is_unicode_mark (&info[i]);
		   return true;
		 })
    | hb_enumerate
    | machine_index
    ;
  auto pe = p + p.len ();
  auto eof = +pe;
  auto ts = +p;
  auto te = +p;
  unsigned int act HB_UNUSED;
  int cs;
  %%{
    write init;
    getkey (*p).second.second.use_category();
  }%%

  unsigned int syllable_serial = 1;
  %%{
    write exec;
  }%%
}

#undef found_syllable

#endif /* HB_OT_SHAPE_COMPLEX_USE_MACHINE_HH */
