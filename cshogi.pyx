﻿# distutils: sources = ["bitboard.cpp", "common.cpp", "generateMoves.cpp", "hand.cpp", "init.cpp", "move.cpp", "mt64bit.cpp", "position.cpp", "square.cpp", "usi.cpp"]
# distutils: language = c++
# distutils: define_macros=HAVE_SSE4
# distutils: define_macros=HAVE_BMI2
# distutils: define_macros=HAVE_AVX2

from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp cimport bool

import numpy as np

HuffmanCodedPos = np.dtype([
    ('hcp', np.uint8, 32),
    ])

HuffmanCodedPosAndEval = np.dtype([
    ('hcp', np.uint8, 32),
    ('eval', np.int16),
    ('bestMove16', np.uint16),
    ('gameResult', np.uint8),
    ('dummy', np.uint8),
    ])

PackedSfen = np.dtype([
    ('sfen', np.uint8, 32),
    ])

PackedSfenValue = np.dtype([
    ('sfen', np.uint8, 32),
    ('score', np.int16),
    ('move', np.uint16),
    ('gamePly', np.uint16),
    ('game_result', np.uint8),
    ('padding', np.uint8),
    ])

SQUARES = [
	A1, B1, C1, D1, E1, F1, G1, H1, I1,
	A2, B2, C2, D2, E2, F2, G2, H2, I2,
	A3, B3, C3, D3, E3, F3, G3, H3, I3,
	A4, B4, C4, D4, E4, F4, G4, H4, I4,
	A5, B5, C5, D5, E5, F5, G5, H5, I5,
	A6, B6, C6, D6, E6, F6, G6, H6, I6,
	A7, B7, C7, D7, E7, F7, G7, H7, I7,
	A8, B8, C8, D8, E8, F8, G8, H8, I8,
	A9, B9, C9, D9, E9, F9, G9, H9, I9,
] = range(81)

COLORS = [BLACK, WHITE] = range(2)

GAME_RESULT = [
    Draw, BlackWin, WhiteWin,
] = range(3)

PIECE_TYPES_WITH_NONE = [NONE,
           PAWN,      LANCE,      KNIGHT,      SILVER,
         BISHOP,       ROOK,
           GOLD,
           KING,
      PROM_PAWN, PROM_LANCE, PROM_KNIGHT, PROM_SILVER,
    PROM_BISHOP,  PROM_ROOK,
] = range(15)

PIECE_TYPES = [
           PAWN,      LANCE,      KNIGHT,      SILVER,
         BISHOP,       ROOK,
           GOLD,
           KING,
      PROM_PAWN, PROM_LANCE, PROM_KNIGHT, PROM_SILVER,
    PROM_BISHOP,  PROM_ROOK,
]

PIECES = [NONE,
          BPAWN,      BLANCE,      BKNIGHT,      BSILVER,
        BBISHOP,       BROOK,
          BGOLD,
          BKING,
     BPROM_PAWN, BPROM_LANCE, BPROM_KNIGHT, BPROM_SILVER,
   BPROM_BISHOP,  BPROM_ROOK,       NOTUSE,       NOTUSE,
          WPAWN,      WLANCE,      WKNIGHT,      WSILVER,
        WBISHOP,       WROOK,
          WGOLD,
          WKING,
     WPROM_PAWN, WPROM_LANCE, WPROM_KNIGHT, WPROM_SILVER,
   WPROM_BISHOP, WPROM_ROOK,
] = range(31)

REPETITION_TYPES = [
    NOT_REPETITION, REPETITION_DRAW, REPETITION_WIN, REPETITION_LOSE,
    REPETITION_SUPERIOR, REPETITION_INFERIOR
] = range(6)

cdef extern from "init.hpp":
	void initTable()

initTable()

cdef extern from "position.hpp":
	cdef cppclass Position:
		@staticmethod
		void initZobrist()

Position.initZobrist()

cdef extern from "cshogi.h":
	void HuffmanCodedPos_init()

HuffmanCodedPos_init()

cdef extern from "cshogi.h":
	string __to_usi(const int move)
	string __to_csa(const int move)

def to_usi(int move):
	return __to_usi(move)

def to_csa(int move):
	return __to_csa(move)

cdef extern from "cshogi.h":
	cdef cppclass __Board:
		__Board() except +
		bool set_hcp(const char* hcp)
		bool set_psfen(const char* psfen)
		void reset()
		void dump() const
		void push(const int move)
		void pop(const int move)
		bool is_game_over() const
		int isDraw() except +
		int move(const int from_square, const int to_square, const bool promotion) const
		int drop_move(const int to_square, const int drop_piece_type) const
		int move_from_usi(const string& usi) const
		int move_from_csa(const string& csa) const
		int move_from_move16(const unsigned short move16) const
		int turn() const
		int ply() const
		string toSFEN() const
		void toHuffmanCodedPos(char* data) const
		int piece(const int sq) const
		bool inCheck() const
		int mateMoveIn1Ply()
		long long getKey() const

cdef class Board:
	cdef __Board __board

	def __cinit__(self, sfen=None):
		self.__board = __Board()
		if sfen is None:
			self.__board.reset()
		else:
			self.__board.set(sfen)

	def set_hcp(self, hcp):
		cdef char[::1] data = hcp
		return self.__board.set_hcp(&data[0])

	def set_psfen(self, psfen):
		cdef char[::1] data = psfen
		return self.__board.set_psfen(&data[0])

	def reset(self):
		self.__board.reset()

	def dump(self):
		self.__board.dump()

	def push(self, int move):
		self.__board.push(move)

	def push_usi(self, string usi):
		move = self.__board.move_from_usi(usi)
		self.__board.push(move)
		return move

	def push_csa(self, string csa):
		move = self.__board.move_from_csa(csa)
		self.__board.push(move)
		return move

	def pop(self, int move):
		self.__board.pop(move)

	def is_game_over(self):
		return self.__board.is_game_over()

	def is_draw(self):
		return self.__board.isDraw()

	def move(self, int from_square, int to_square, bool promotion):
		return self.__board.move(from_square, to_square, promotion)

	def drop_move(self, int to_square, int drop_piece_type):
		return self.__board.drop_move(to_square, drop_piece_type)

	def move_from_usi(self, string usi):
		return self.__board.move_from_usi(usi)

	def move_from_csa(self, string csa):
		return self.__board.move_from_csa(csa)

	def move_from_move16(self, unsigned short move16):
		return self.__board.move_from_move16(move16)

	def leagal_move_list(self):
		return LegalMoveList(self)

	@property
	def turn(self):
		return self.__board.turn()

	@property
	def ply(self):
		return self.__board.ply()

	def sfen(self):
		return self.__board.toSFEN()

	def to_hcp(self, hcp):
		cdef char[::1] data = hcp
		return self.__board.toHuffmanCodedPos(&data[0])

	def piece(self, int sq):
		return self.__board.piece(sq)

	def is_check(self):
		return self.__board.inCheck()

	def mate_move_in_1ply(self):
		return self.__board.mateMoveIn1Ply()

	def zobrist_hash(self):
		return self.__board.getKey()


cdef extern from "cshogi.h":
	cdef cppclass __LegalMoveList:
		__LegalMoveList() except +
		__LegalMoveList(const __Board& board) except +
		bool end() const
		int move() const
		void next()
		int size() const

	int __move_to(const int move)
	int __move_from(const int move)
	int __move_cap(const int move)
	bool __move_is_promotion(const int move)
	unsigned short __move16(const int move)
	string __move_to_usi(const int move)
	string __move_to_csa(const int move)

cdef class LegalMoveList:
	cdef __LegalMoveList __ml

	def __cinit__(self, Board board):
		self.__ml = __LegalMoveList(board.__board)

	def __iter__(self):
		return self

	def __next__(self):
		if self.__ml.end():
			raise StopIteration()
		move = self.__ml.move()
		self.__ml.next()
		return move

	def __len__(self):
		return self.__ml.size()

def move_to(int move):
	return __move_to(move)

def move_from(int move):
	return __move_from(move)

def move_cap(int move):
	return __move_cap(move)

def move_is_promotion(int move):
	return __move_is_promotion(move)

def move16(int move):
	return __move16(move)

def move_to_usi(int move):
	return __move_to_usi(move)

def move_to_csa(int move):
	return __move_to_csa(move)

cdef extern from "parser.h" namespace "parser":
	cdef cppclass __Parser:
		__Parser() except +
		string sfen
		string endgame
		vector[string] names
		vector[float] ratings
		vector[int] moves
		vector[int] scores
		int win
		void parse_csa_file(const string& path) except +
		void parse_csa_str(const string& csa_str) except +

cdef class Parser:
	cdef __Parser __parser

	def __cinit__(self):
		self.__parser = __Parser()

	def parse_csa_file(self, string path):
		self.__parser.parse_csa_file(path)

	def parse_csa_str(self, string csa_str):
		self.__parser.parse_csa_str(csa_str)

	@property
	def sfen(self):
		return self.__parser.sfen

	@property
	def endgame(self):
		return self.__parser.endgame

	@property
	def names(self):
		return self.__parser.names

	@property
	def ratings(self):
		return self.__parser.ratings

	@property
	def moves(self):
		return self.__parser.moves

	@property
	def scores(self):
		return self.__parser.scores

	@property
	def win(self):
		return self.__parser.win
