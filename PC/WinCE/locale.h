/*
 *	On Windows/CE we need to have our own locale.h because Pocket PC 2002 doesn't have one
 */
#ifndef	_LOCALE_H
#define	_LOCALE_H	1

#define LC_ALL          0
#define LC_COLLATE      1
#define LC_CTYPE        2
#define LC_MONETARY     3
#define LC_NUMERIC      4
#define LC_TIME         5

struct lconv {
        char *decimal_point;
	char *int_curr_symbol;
	char *currency_symbol;
	char *mon_decimal_point;
	char *mon_thousands_sep;
	char *mon_grouping;
	char *positive_sign;
	char *negative_sign;
	char *grouping;
	char *thousands_sep;
	char int_frac_digits;
	char frac_digits;
	char p_cs_precedes;
	char p_sep_by_space;
	char n_cs_precedes;
	char n_sep_by_space;
	char p_sign_posn;
	char n_sign_posn;
	};

extern struct lconv *localeconv(void);
extern char *setlocale(int category, const char *locale);

#endif	/* _LOCALE_H */
