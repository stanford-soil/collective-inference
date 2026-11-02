"""Shared constants and helpers for the Python scripts: repository paths, condition
names, labels and palette, and the Experiment 2 SR network list.

Scripts import it with
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib'))
    import common
so they can be run from any folder.
"""
import os
import pandas as pd

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))


def repo_path(*parts):
    return os.path.join(REPO, *parts)


# Data files. The derived files are written by prep/ and are not committed.
EXP1_RAW = repo_path('data', 'exp1', 'raw')
EXP2_RAW = repo_path('data', 'exp2', 'raw')
EXP1_MERGED = repo_path('data', 'exp1', 'PreregMergedGuesses.csv')
EXP1_EXTRACTED_MSGS = repo_path('data', 'exp1', 'raw', '1_extracted_msgs_prereg', 'extracted_messages.csv')
EXP1_CLEAN = repo_path('data', 'derived', 'exp1_clean_data.csv')
EXP2_CLEAN = repo_path('data', 'derived', 'exp2_clean_data.csv')
EXP2_CODED_MSGS = repo_path('data', 'exp2', 'coded_messages.csv')
EXP2_SR_GAMES = repo_path('lib', 'exp2_sr_games.csv')
EXP1_PARTNERS = repo_path('partner_schedule', 'exp1_partners.csv')
EXP2_PARTNERS = repo_path('partner_schedule', 'exp2_partners.csv')
FIT_RESULTS = repo_path('models', 'fit_results.csv')
FIGURES = repo_path('figures')

# Condition names in the data and code, and the labels used in the revised manuscript
CONDITIONS = ['slider', 'unidirectional', 'interactive']
CONDITION_LABELS = {
    'slider': 'Slider (numerical estimates)',
    'unidirectional': 'Delayed messaging',
    'interactive': 'Real-time messaging',
}
CONDITION_COLORS = {
    'slider': '#E69F00',
    'unidirectional': '#56B4E9',
    'interactive': '#009E73',
}


def sr_games():
    """Experiment 2 networks analysed in the paper (SR treatments, both conditions).
    RS networks are excluded because their slider messages were inverted."""
    return set(pd.read_csv(EXP2_SR_GAMES).gameID)


def exp2_subset(default='SR'):
    """Experiment 2 subset to analyse: SR (default), RS or ALL; environment variable SUBSET."""
    s = os.environ.get('SUBSET', '') or default
    assert s in ('SR', 'RS', 'ALL'), s
    return s


def filter_exp2(df, subset=None, col='gameID'):
    """Restrict an Experiment 2 table to the SR networks (or RS / ALL)."""
    subset = subset or exp2_subset()
    if subset == 'ALL':
        return df
    sr = df[col].isin(sr_games())
    return df[sr] if subset == 'SR' else df[~sr]
