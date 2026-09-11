package auth

import (
	"errors"

	"hris-backend/internal/common"
	"hris-backend/internal/config"
	"hris-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
)

var ErrInvalidCredentials = errors.New("invalid email or password")

type Service struct {
	repo *Repository
	cfg  *config.Config
}

func NewService(repo *Repository, cfg *config.Config) *Service {
	return &Service{repo: repo, cfg: cfg}
}

func (s *Service) Login(email, password string) (*TokenResponse, error) {
	user, err := s.repo.FindByEmail(email)
	if err != nil {
		return nil, ErrInvalidCredentials
	}
	if !user.IsActive {
		return nil, errors.New("account is inactive")
	}
	if bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)) != nil {
		return nil, ErrInvalidCredentials
	}
	return s.issueTokens(user)
}

func (s *Service) Refresh(refreshToken string) (*TokenResponse, error) {
	claims, err := common.ParseToken(s.cfg.JWTSecret, refreshToken)
	if err != nil || claims.Type != common.TokenRefresh {
		return nil, errors.New("invalid refresh token")
	}
	user, err := s.repo.FindByID(claims.Subject)
	if err != nil {
		return nil, errors.New("user not found")
	}
	return s.issueTokens(user)
}

func (s *Service) Me(userID string) (*models.User, error) {
	return s.repo.FindByID(userID)
}

func (s *Service) issueTokens(user *models.User) (*TokenResponse, error) {
	empID := ""
	if user.Employee != nil {
		empID = user.Employee.ID
	}
	access, err := common.GenerateToken(s.cfg.JWTSecret, user.ID, empID, string(user.Role), common.TokenAccess, s.cfg.AccessTokenDuration)
	if err != nil {
		return nil, err
	}
	refresh, err := common.GenerateToken(s.cfg.JWTSecret, user.ID, empID, string(user.Role), common.TokenRefresh, s.cfg.RefreshTokenDuration)
	if err != nil {
		return nil, err
	}
	return &TokenResponse{AccessToken: access, RefreshToken: refresh, TokenType: "Bearer"}, nil
}
