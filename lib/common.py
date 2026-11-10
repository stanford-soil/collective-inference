"""Shared by every Python script: file paths, condition names, and the list of
analysed Experiment 2 networks.

Scripts import it with
    import sys; sys.path.insert(0, '../lib'); import common
and are run from their own folder.
"""
import os
import pandas as pd

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))


def repo_path(*parts):
    return os.path.join(REPO, *parts)


def derived(filename):
    """A file in data/derived/ (written by prep/, not committed)."""
    return repo_path('data', 'derived', filename)


EXP1_RAW = repo_path('data', 'exp1', 'raw')
EXP1_MERGED = repo_path('data', 'exp1', 'PreregMergedGuesses.csv')
EXP1_EXTRACTED_MSGS = repo_path('data', 'exp1', 'raw', '1_extracted_msgs_prereg', 'extracted_messages.csv')
EXP1_CLEAN = derived('exp1_clean_data.csv')
EXP1_MESSAGES = derived('exp1_messages_raw.csv')
EXP1_PARTNERS = repo_path('partner_schedule', 'exp1_partners.csv')

EXP2_RAW = repo_path('data', 'exp2', 'raw')
EXP2_CLEAN = derived('exp2_clean_data.csv')
EXP2_CHAT = derived('exp2_chat_raw.csv')
EXP2_PARTNERS = repo_path('partner_schedule', 'exp2_partners.csv')
EXP2_CODED_MSGS = repo_path('data', 'exp2', 'coded_messages.csv')
EXP2_FINAL_CODES = repo_path('coding', 'exp2_message_codes_final.csv')
EXP2_SR_GAMES = repo_path('lib', 'exp2_sr_games.csv')

FIT_RESULTS = repo_path('models', 'fit_results.csv')
FIGURES = repo_path('figures')

# The data use the original condition names; the paper uses the labels below.
CONDITION_LABELS = {
    'slider': 'Slider (numerical estimates)',
    'unidirectional': 'Batched messaging',
    'interactive': 'Live messaging',
}
# Experiment 2 had only the live version of messaging, called "messaging" in the paper.
EXP2_CONDITION_LABELS = {
    'slider': 'Slider (numerical estimates)',
    'interactive': 'Messaging',
}
CONDITION_COLORS = {
    'slider': '#E69F00',
    'unidirectional': '#56B4E9',
    'interactive': '#009E73',
}


def sr_games():
    """The Experiment 2 networks analysed in the paper (slider version "SR", both
    conditions). Networks with the "RS" version are excluded because their slider
    messages were inverted (see README, correction 2)."""
    return set(pd.read_csv(EXP2_SR_GAMES).gameID)


def keep_sr(table):
    """Keep the rows of an Experiment 2 table that belong to the analysed networks."""
    return table[table.gameID.isin(sr_games())]
